{ config, secrets, ... }:

let
  networkInterface = "enp11s0";
  hysteria2 = import "${secrets}/hysteria2.nix";
in
{
  services.sing-box = {
    enable = true;
    settings = {
      dns = {
        servers = [
          {
            type = "local";
            tag = "dns-direct";
          }
        ];
        final = "dns-direct";
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
