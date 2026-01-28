{
  pkgs,
  config,
  secrets,
  ...
}:

let
  wgInterface = "wg0";
  allowedIp = "10.100.0.0/24";
  censoredIp = "10.100.0.100";
  dokodemoTcpPort = 12345;
  xtls = import "${secrets}/xtls.nix";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.route_localnet" = 1;
  };

  networking.firewall.trustedInterfaces = [ wgInterface ];
  networking.wireguard.interfaces.${wgInterface} = {
    ips = [ "10.100.0.2/24" ];
    privateKeyFile = config.age.secrets.wireguardKey.path;

    postSetup = ''
      ${pkgs.iptables}/bin/iptables -t nat -N XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t nat -F XRAY
      ${pkgs.iptables}/bin/iptables -t nat -A XRAY -m mark --mark 2 -j RETURN
      ${pkgs.iptables}/bin/iptables -t nat -A XRAY -s ${allowedIp} -d ${censoredIp} -p tcp -j REDIRECT --to-ports ${toString dokodemoTcpPort}
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

  services.xray.enable = true;
  networking.firewall.allowedTCPPorts = [ 1080 ];
  services.xray.settings.inbounds = [
    {
      port = dokodemoTcpPort;
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
      port = 1080;
      protocol = "socks";
      listen = "0.0.0.0";
      settings = {
        udp = true;
      };
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
