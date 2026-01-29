{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:

let
  wgInterface = "wg0";
  allowedIp = "10.100.0.0/24";
  dokodemoPort = 12345;
  constants = import ./constants.nix;
  xtls = import "${secrets}/xtls.nix";

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
      ${pkgs.iptables}/bin/iptables -t nat -N XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t nat -F XRAY
      ${pkgs.iptables}/bin/iptables -t nat -A XRAY -s ${allowedIp} -d ${censoredIp} -p tcp -j REDIRECT --to-ports ${toString dokodemoPort}
      ${pkgs.iptables}/bin/iptables -t nat -D PREROUTING -i ${wgInterface} -j XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t nat -I PREROUTING -i ${wgInterface} -j XRAY
    '';

    postShutdown = ''
      ${pkgs.iptables}/bin/iptables -t nat -D PREROUTING -i ${wgInterface} -j XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t nat -F XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t nat -X XRAY 2>/dev/null || true
    '';

    peers = [
      {
        publicKey = "mL2pYNjMdCjaW1CCFTVxeKUIbjlv3/Bg5vw0yfEO6H8=";
        allowedIPs = [ "${allowedIp}" ];
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
        network = "tcp";
        followRedirect = true;
      };
      sniffing = {
        enabled = true;
        routeOnly = false;
        metadataOnly = false;
        destOverride = [
          "http"
          "tls"
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
                flow = "xtls-rprx-vision";
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
      };
    }
  ];
}
