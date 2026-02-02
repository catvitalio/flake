{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:

let
  wgInterface = "wg0";
  dokodemoPort = 12345;
  constants = import ./constants.nix;
  xtls = import "${secrets}/xtls.nix";

  ip = "${pkgs.iproute2}/bin/ip";
  ipt = "${pkgs.iptables}/bin/iptables -t mangle";
  tproxyMark = 1;
  xrayBypassMark = 2;
  quiet = "2>/dev/null || true";

  censoredIp = "10.100.0.100";
  censoredDomains = import ./censoredDomains { inherit lib; };
  censoredAddresses = lib.concatMap (domain: [
    "/${domain}/${censoredIp}"
    "/${domain}/::"
  ]) censoredDomains;
in
{
  services.dnsmasq.settings.address = lib.mkAfter censoredAddresses;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.route_localnet" = 1;
  };

  networking.wireguard.interfaces.${wgInterface} = {
    ips = [ "${constants.wireguard.address}/24" ];
    privateKeyFile = config.age.secrets.wireguardKey.path;

    postSetup = ''
      ${ip} route add local default dev lo table 100 ${quiet}
      ${ip} rule add fwmark ${toString tproxyMark} table 100 ${quiet}
      ${ip} rule add fwmark ${toString xrayBypassMark} lookup main pref 100 ${quiet}

      ${ipt} -N XRAY ${quiet}
      ${ipt} -F XRAY
      ${ipt} -A XRAY -j CONNMARK --restore-mark
      ${ipt} -A XRAY -m mark ! --mark 0 -j RETURN
      ${ipt} -A XRAY -d ${censoredIp} -p tcp -j TPROXY --on-port ${toString dokodemoPort} --tproxy-mark ${toString tproxyMark}
      ${ipt} -A XRAY -d ${censoredIp} -p udp -j TPROXY --on-port ${toString dokodemoPort} --tproxy-mark ${toString tproxyMark}
      ${ipt} -A XRAY -m mark --mark ${toString tproxyMark} -j CONNMARK --save-mark
      ${ipt} -D PREROUTING -i ${wgInterface} -j XRAY ${quiet}
      ${ipt} -I PREROUTING -i ${wgInterface} -j XRAY

      ${ipt} -D OUTPUT -m owner --uid-owner xray -j MARK --set-mark ${toString xrayBypassMark} ${quiet}
      ${ipt} -I OUTPUT -m owner --uid-owner xray -j MARK --set-mark ${toString xrayBypassMark}
    '';

    postShutdown = ''
      ${ipt} -D PREROUTING -i ${wgInterface} -j XRAY ${quiet}
      ${ipt} -D OUTPUT -m owner --uid-owner xray -j MARK --set-mark ${toString xrayBypassMark} ${quiet}
      ${ipt} -F XRAY ${quiet}
      ${ipt} -X XRAY ${quiet}

      ${ip} rule del fwmark ${toString xrayBypassMark} lookup main pref 100 ${quiet}
      ${ip} rule del fwmark ${toString tproxyMark} table 100 ${quiet}
      ${ip} route del local default dev lo table 100 ${quiet}
    '';

    peers = [
      {
        publicKey = "mL2pYNjMdCjaW1CCFTVxeKUIbjlv3/Bg5vw0yfEO6H8=";
        allowedIPs = [ "10.100.0.0/24" ];
        endpoint = "192.168.1.1:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  networking.firewall.trustedInterfaces = [ wgInterface ];

  services.xray.enable = true;
  services.xray.settings.inbounds = [
    {
      port = dokodemoPort;
      protocol = "dokodemo-door";
      settings = {
        network = "tcp,udp";
        followRedirect = true;
      };
      streamSettings = {
        sockopt = {
          tproxy = "tproxy";
        };
      };
      sniffing = {
        enabled = true;
        routeOnly = true;
        metadataOnly = false;
        destOverride = [
          "http"
          "tls"
          "quic"
        ];
      };
    }
    {
      port = constants.xray.socksPort;
      protocol = "socks";
      listen = constants.wireguard.address;
      settings = {
        udp = true;
      };
    }
    {
      port = constants.xray.httpPort;
      protocol = "http";
      listen = constants.wireguard.address;
    }
  ];
  services.xray.settings.outbounds = [
    {
      protocol = "vless";
      settings = {
        domainStrategy = "UseIP";
        vnext = [
          {
            address = xtls.address;
            port = 443;
            users = [
              {
                id = xtls.id;
                encryption = "none";
                flow = "xtls-rprx-vision-udp443";
              }
            ];
          }
        ];
      };
      streamSettings = {
        network = "tcp";
        security = "tls";
        tlsSettings = {
          serverName = xtls.address;
          allowInsecure = false;
          fingerprint = "chrome";
        };
        sockopt = {
          mark = xrayBypassMark;
        };
      };
    }
  ];
}
