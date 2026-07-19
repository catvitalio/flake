{ config, secrets, ... }:

let
  work = import "${secrets}/work.nix";
  dns = import ../../profiles/dns.nix;
in

let
  adguardDomain = "adguard.catvitalio.com";
  adguardAddress = "127.0.0.1";
  adguardPort = 5354;
  adguardDnsPort = 5353;
in
{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      listen-address = "0.0.0.0";
      bind-interfaces = true;
      port = 53;
      server = [
        "${adguardAddress}#${toString adguardDnsPort}"
        "/${work.domain_suffix}/${work.dns_server}"
      ];
    };
  };

  services.adguardhome = {
    enable = true;
    host = adguardAddress;
    port = adguardPort;
    settings = {
      dns = {
        bind_hosts = [ adguardAddress ];
        port = adguardDnsPort;
        upstream_dns = [
          "https://common.dot.dns.yandex.net/dns-query"
          "https://dns.google/dns-query"
          "https://cloudflare-dns.com/dns-query"
        ];
        bootstrap_dns = [ dns.bootstrap ];
        fallback_dns = [ dns.bootstrap ];
        upstream_mode = "parallel";
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;
      };
      filters =
        map
          (url: {
            enabled = true;
            url = url;
          })
          [
            "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
          ];
    };
  };

  my.reverseProxy.${adguardDomain}.proxyPass = "http://${adguardAddress}:${toString adguardPort}";

}
