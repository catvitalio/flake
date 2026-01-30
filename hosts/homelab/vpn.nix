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
      # Policy-based routing для TPROXY
      ${pkgs.iproute2}/bin/ip route add local default dev lo table 100 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule add fwmark 1 table 100 2>/dev/null || true
      # Разрешить трафик с mark 2 идти обычным путем (в обход TPROXY)
      ${pkgs.iproute2}/bin/ip rule add fwmark 2 lookup main pref 100 2>/dev/null || true

      # TPROXY правила в mangle таблице для PREROUTING
      ${pkgs.iptables}/bin/iptables -t mangle -N XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -F XRAY

      # Восстановить connmark для существующих соединений
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY -j CONNMARK --restore-mark
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY -m mark --mark 2 -j RETURN

      # TPROXY для TCP и UDP
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY -s ${allowedIp} -d ${censoredIp} -p tcp -j TPROXY --on-port ${toString dokodemoPort} --tproxy-mark 1
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY -s ${allowedIp} -d ${censoredIp} -p udp -j TPROXY --on-port ${toString dokodemoPort} --tproxy-mark 1

      # Сохранить mark в connmark
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY -j CONNMARK --save-mark

      ${pkgs.iptables}/bin/iptables -t mangle -D PREROUTING -i ${wgInterface} -j XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -I PREROUTING -i ${wgInterface} -j XRAY

      # OUTPUT правила для локально генерируемых пакетов
      ${pkgs.iptables}/bin/iptables -t mangle -N XRAY_OUTPUT 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -F XRAY_OUTPUT

      # Маркировать весь трафик от Xray mark 2 ПЕРЕД restore (избегаем петли)
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY_OUTPUT -m owner --uid-owner xray -j MARK --set-mark 2
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY_OUTPUT -m mark --mark 2 -j RETURN

      # Восстановить connmark для остального трафика
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY_OUTPUT -j CONNMARK --restore-mark

      # Сохранить mark в connmark
      ${pkgs.iptables}/bin/iptables -t mangle -A XRAY_OUTPUT -j CONNMARK --save-mark

      ${pkgs.iptables}/bin/iptables -t mangle -D OUTPUT -j XRAY_OUTPUT 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -I OUTPUT -j XRAY_OUTPUT
    '';

    postShutdown = ''
      # Удаление TPROXY правил
      ${pkgs.iptables}/bin/iptables -t mangle -D PREROUTING -i ${wgInterface} -j XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -D OUTPUT -j XRAY_OUTPUT 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -F XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -X XRAY 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -F XRAY_OUTPUT 2>/dev/null || true
      ${pkgs.iptables}/bin/iptables -t mangle -X XRAY_OUTPUT 2>/dev/null || true

      # Удаление policy routing
      ${pkgs.iproute2}/bin/ip rule del fwmark 2 lookup main pref 100 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip rule del fwmark 1 table 100 2>/dev/null || true
      ${pkgs.iproute2}/bin/ip route del local default dev lo table 100 2>/dev/null || true
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
  services.xray.settings.log = {
    loglevel = "debug";
  };
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
        routeOnly = false;
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
          mark = 2;
        };
      };
    }
  ];
}
