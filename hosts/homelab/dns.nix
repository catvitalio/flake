{ lib, config, ... }:

let
  adguardDomain = "adguard.catvitalio.com";
  adguardAddress = "127.0.0.1";
  adguardPort = 5354;
  adguardDnsPort = 5353;
  constants = import ./constants.nix;
in
{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      listen-address = constants.wireguard.address;
      bind-interfaces = true;
      port = 53;
      server = [
        "${adguardAddress}#${toString adguardDnsPort}"
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
            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_1_Russian/filter.txt"
            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_14_Annoyances/filter.txt"
            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_15_DnsFilter/filter.txt"
            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_17_TrackParam/filter.txt"
          ];
    };
  };

  services.nginx.virtualHosts.${adguardDomain} = {
    useACMEHost = adguardDomain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${adguardAddress}:${toString adguardPort}";
    };
  };

  security.acme.certs.${adguardDomain} = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.acmeEnv.path;
    reloadServices = [ "nginx" ];
  };

  services.dnsmasq.settings.address = lib.mkAfter [
    "/${adguardDomain}/${constants.wireguard.address}"
  ];

}
