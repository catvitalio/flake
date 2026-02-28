{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:

let
  wgInterface = "wg0";
  constants = import ./constants.nix;

  hysteria2 = import "${secrets}/hysteria2.nix";

  ip = "${pkgs.iproute2}/bin/ip";
  ipt = "${pkgs.iptables}/bin/iptables -t mangle";
  tproxyPort = 12345;
  tproxyMark = 1;
  tproxyBypassMark = 2;
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
      ${ip} rule add fwmark ${toString tproxyBypassMark} lookup main pref 100 ${quiet}

      ${ipt} -N SINGBOX ${quiet}
      ${ipt} -F SINGBOX
      ${ipt} -A SINGBOX -j CONNMARK --restore-mark
      ${ipt} -A SINGBOX -m mark ! --mark 0 -j RETURN
      ${ipt} -A SINGBOX -d ${censoredIp} -p tcp -j TPROXY --on-port ${toString tproxyPort} --tproxy-mark ${toString tproxyMark}
      ${ipt} -A SINGBOX -m mark --mark ${toString tproxyMark} -j CONNMARK --save-mark
      ${ipt} -D PREROUTING -i ${wgInterface} -j SINGBOX ${quiet}
      ${ipt} -I PREROUTING -i ${wgInterface} -j SINGBOX

      ${ipt} -D OUTPUT -m owner --uid-owner sing-box -j MARK --set-mark ${toString tproxyBypassMark} ${quiet}
      ${ipt} -I OUTPUT -m owner --uid-owner sing-box -j MARK --set-mark ${toString tproxyBypassMark}
    '';

    postShutdown = ''
      ${ipt} -D PREROUTING -i ${wgInterface} -j SINGBOX ${quiet}
      ${ipt} -D OUTPUT -m owner --uid-owner sing-box -j MARK --set-mark ${toString tproxyBypassMark} ${quiet}
      ${ipt} -F SINGBOX ${quiet}
      ${ipt} -X SINGBOX ${quiet}

      ${ip} rule del fwmark ${toString tproxyBypassMark} lookup main pref 100 ${quiet}
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

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "debug";
      };
      inbounds = [
        {
          type = "tproxy";
          tag = "inbound:tproxy-tcp";
          listen = constants.wireguard.address;
          listen_port = tproxyPort;
          network = "tcp";
          sniff = true;
          sniff_override_destination = true;
          sniff_timeout = "2s";
          domain_strategy = "prefer_ipv4";
        }
        {
          type = "socks";
          tag = "inbound:socks";
          listen = constants.wireguard.address;
          listen_port = constants.singBox.socksPort;
        }
        {
          type = "http";
          tag = "inbound:http";
          listen = constants.wireguard.address;
          listen_port = constants.singBox.httpPort;
        }
      ];
      outbounds = [
        {
          type = "hysteria2";
          tag = "outbound:hy2";
          server = hysteria2.domain;
          server_port = 443;
          password = hysteria2.password;
          tls = {
            enabled = true;
            server_name = hysteria2.domain;
            alpn = [ "h3" ];
          };
        }
      ];
      route = {
        final = "outbound:hy2";
        rules = [
          {
            action = "sniff";
          }
        ];
      };
    };
  };
}
