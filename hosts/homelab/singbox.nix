{ secrets, ... }:

let
  hysteria2 = import "${secrets}/hysteria2.nix";
  work = import "${secrets}/work.nix";
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
          stack = "system";
          address = [
            "172.19.0.1/30"
            "fdfe:dcba:9876::1/126"
          ];
          auto_route = true;
          strict_route = false;
          sniff = true;
          route_exclude_address = [
            work.subnet
            "10.100.0.0/24"
            "100.64.0.0/10"
            "169.254.0.0/16"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "77.88.8.8/32"
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
          type = "direct";
          tag = "outbound:local";
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
        default_mark = 200;
        rules = [
          {
            protocol = "dns";
            action = "hijack-dns";
          }
          {
            domain_suffix = [ ".catvitalio.com" ];
            outbound = "outbound:local";
          }
          {
            domain = [
              "common.dot.dns.yandex.net"
            ];
            outbound = "outbound:direct";
          }
          {
            domain_suffix = [
              "avito.ru"
              "avito.st"
              "uxfeedback.ru"
            ];
            outbound = "outbound:direct";
          }
          {
            rule_set = [
              "geosite-microsoft"
              "geosite-openai"
              "geosite-anthropic"
            ];
            outbound = "outbound:hy2";
          }
          {
            rule_set = [
              "geosite-ea"
              "geosite-origin"
              "geosite-steam"
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
            download_detour = "outbound:direct";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-microsoft";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-microsoft.srs";
            download_detour = "outbound:direct";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-openai";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-openai.srs";
            download_detour = "outbound:direct";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-anthropic";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-anthropic.srs";
            download_detour = "outbound:direct";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-ea";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-ea.srs";
            download_detour = "outbound:direct";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-origin";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-origin.srs";
            download_detour = "outbound:direct";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-steam";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-steam.srs";
            download_detour = "outbound:direct";
            update_interval = "24h0m0s";
          }
        ];
      };
    };
  };
}
