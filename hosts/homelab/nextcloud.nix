{
  pkgs,
  config,
  ...
}:

let
  domain = "nextcloud.catvitalio.com";
in
{
  services.nextcloud = {
    enable = true;
    https = true;
    configureRedis = true;
    hostName = domain;
    package = pkgs.nextcloud32;
    config = {
      dbtype = "sqlite";
      adminuser = "root";
      adminpassFile = config.age.secrets.nextcloudPass.path;
    };
  };

  services.nginx.virtualHosts.${domain} = {
    useACMEHost = domain;
    forceSSL = true;
  };

  security.acme.certs.${domain} = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.acmeEnv.path;
    reloadServices = [ "nginx" ];
  };
}
