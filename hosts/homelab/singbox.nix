{ secrets, ... }:

let
  hysteria2 = import "${secrets}/hysteria2.nix";
in
{
  networking.firewall.trustedInterfaces = [ "singbox0" ];
  networking.firewall.checkReversePath = "loose";

  services.sing-box = {
    enable = true;
    settings = {
      dns = {
        servers = [
          {
            type = "udp";
            tag = "dns-dnsmasq";
            server = "127.0.0.1";
          }
        ];
        final = "dns-dnsmasq";
      };

      inbounds = [
        {
          type = "tun";
          tag = "inbound:tun";
          interface_name = "singbox0";
          address = [
            "172.19.0.1/30"
            "fdfe:dcba:9876::1/126"
          ];
          auto_route = true;
          strict_route = false;
          sniff = true;
          route_exclude_address = [
            "10.100.0.0/24"
            "100.64.0.0/10"
            "169.254.0.0/16"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "::1/128"
            "fc00::/7"
            "fe80::/10"
          ];
        }
      ];

      outbounds = [
        {
          type = "direct";
          tag = "outbound:direct";
          bind_interface = "eno1";
        }
        {
          type = "hysteria2";
          tag = "outbound:hy2";
          bind_interface = "eno1";
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
        default_interface = "eno1";
        rules = [
          {
            protocol = "dns";
            action = "hijack-dns";
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
