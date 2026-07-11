{
  pkgs,
  secrets,
  config,
  ...
}:

let
  hysteria2 = import "${secrets}/hysteria2.nix";
  work = import "${secrets}/work.nix";
  dns = import ../../profiles/dns.nix;
  domain = "clash.catvitalio.com";
in
{
  networking.firewall.trustedInterfaces = [ "singbox0" ];
  networking.firewall.checkReversePath = "loose";

  services.sing-box = {
    enable = true;
    settings = {
      dns = {
        strategy = "ipv4_only";
        servers = [
          {
            type = "udp";
            tag = "dns-dnsmasq";
            server = "127.0.0.1";
          }
          {
            type = "udp";
            tag = "dns-bootstrap";
            server = dns.bootstrap;
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
          mtu = 1280;
          stack = "gvisor";
          address = [ "172.19.0.1/30" ];
          auto_route = true;
          strict_route = false;
          sniff = true;
          route_exclude_address = [
            work.subnet
            "${dns.bootstrap}/32"
            "10.100.0.0/24"
            "100.64.0.0/10"
            "169.254.0.0/16"
            "172.16.0.0/12"
            "192.168.0.0/16"
          ];
        }
      ];

      outbounds = [
        {
          type = "direct";
          tag = "outbound:direct";
          bind_interface = "eno1";
          domain_resolver = "dns-bootstrap";
        }
        {
          type = "direct";
          tag = "outbound:local";
        }
        {
          type = "hysteria2";
          tag = "outbound:hy2";
          bind_interface = "eno1";
          domain_resolver = "dns-bootstrap";
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

      experimental = {
        clash_api = {
          external_controller = "127.0.0.1:9090";
          external_ui = "${pkgs.metacubexd}";
        };
      };

      route = {
        final = "outbound:hy2";
        default_interface = "eno1";
        default_mark = 200;
        default_domain_resolver = "dns-dnsmasq";
        rules = [
          {
            rule_set = [
              "geoip-ru"
              "geosite-ea"
              "geosite-origin"
              "geosite-steam"
              "geosite-apple"
            ];
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
          {
            type = "remote";
            tag = "geosite-ea";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-ea.srs";
            download_detour = "outbound:hy2";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-origin";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-origin.srs";
            download_detour = "outbound:hy2";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-steam";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-steam.srs";
            download_detour = "outbound:hy2";
            update_interval = "24h0m0s";
          }
          {
            type = "remote";
            tag = "geosite-apple";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-apple.srs";
            download_detour = "outbound:hy2";
            update_interval = "24h0m0s";
          }
        ];
      };
    };
  };

  services.nginx.virtualHosts.${domain} = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9090";
      proxyWebsockets = true;
    };
    locations."= /" = {
      return = "301 /ui/";
    };
  };

  security.acme.certs.${domain} = {
    dnsProvider = "timewebcloud";
    environmentFile = config.age.secrets.acmeEnv.path;
    reloadServices = [ "nginx" ];
  };

  services.dnsmasq.settings.address = [ "/${domain}/10.100.0.1" ];
}
