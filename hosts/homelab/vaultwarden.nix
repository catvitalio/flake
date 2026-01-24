{ config, ... }:

let
  domain = "bitwarden.catvitalio.com";
  address = "127.0.0.1";
  port = 8222;
in
{
  services.vaultwarden = {
    enable = true;
    config = {
      domain = "https://${domain}";
      signupsAllowed = true;
      rocketAddress = address;
      rocketPort = port;
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
}
