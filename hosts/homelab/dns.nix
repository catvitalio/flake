{ lib, config, ... }:

let
  domain = "adguard.catvitalio.com";
  address = "127.0.0.1";
  port = 5354;
  dnsPort = 5353;
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
        "${address}#${toString dnsPort}"
      ];
      cache-size = 10000;
    };
  };

  services.adguardhome = {
    enable = true;
    host = address;
    port = port;
    settings = {
      dns = {
        bind_hosts = [ address ];
        port = dnsPort;
        upstream_dns = [
          "https://dns.google/dns-query"
          "https://cloudflare-dns.com/dns-query"
        ];
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;
      };
    };
  };

  services.nginx.virtualHosts.${domain} = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${address}:${toString port}";
    };
  };

  security.acme.certs.${domain} = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.acmeEnv.path;
    reloadServices = [ "nginx" ];
  };

  services.dnsmasq.settings.address = lib.mkAfter [
    "/${domain}/${constants.wireguard.address}"
  ];

}
