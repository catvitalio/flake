{
  config,
  secrets,
  ...
}:

let
  wgInterface = "wg0";
  networkInterface = "eno1";
  constants = import ./constants.nix;
  hysteria2 = import "${secrets}/hysteria2.nix";
in
{
  networking.wireguard.interfaces.${wgInterface} = {
    ips = [ "${constants.wireguard.address}/24" ];
    privateKeyFile = config.age.secrets.wireguardKey.path;
  };

  networking.firewall.trustedInterfaces = [ wgInterface ];

  services.sing-box = {
    enable = false;
    settings = {
      dns = {
        servers = [
          {
            type = "udp";
            tag = "dns-dnsmasq";
            server = "127.0.0.1";
            server_port = 53;
            detour = "outbound:direct";
          }
        ];
        final = "dns-dnsmasq";
      };

      inbounds = [
        {
          type = "tun";
          tag = "inbound:tun";
          interface_name = "singbox0";
          address = "172.19.0.1/30";
          auto_route = true;
          strict_route = true;
          auto_redirect = true;
          stack = "system";
        }
        {
          type = "http";
          tag = "inbound:http";
          listen = constants.wireguard.address;
          listen_port = constants.singBox.httpPort;
        }
        {
          type = "socks";
          tag = "inbound:socks";
          listen = constants.wireguard.address;
          listen_port = constants.singBox.socksPort;
        }
      ];

      outbounds = [
        {
          type = "direct";
          tag = "outbound:direct";
          bind_interface = networkInterface;
        }
        {
          type = "hysteria2";
          tag = "outbound:hy2";
          bind_interface = networkInterface;
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
        default_interface = networkInterface;
        rules = [
          {
            protocol = "dns";
            action = "hijack-dns";
          }
          {
            ip_cidr = [
              "10.0.0.0/8"
              "100.64.0.0/10"
              "127.0.0.0/8"
              "169.254.0.0/16"
              "172.16.0.0/12"
              "192.168.0.0/16"
            ];
            outbound = "outbound:direct";
          }
          {
            rule_set = "geoip-ru";
            outbound = "outbound:direct";
          }
        ];
        rule_set = [
          {
            type = "remote";
            tag = "geoip-ru";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs";
            download_detour = "outbound:hy2";
            update_interval = "24h0m0s";
          }
        ];
      };
    };
  };
}
