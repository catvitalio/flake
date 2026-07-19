{ pkgs, config, ... }:

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

  my.reverseProxy.${domain} = { };
}
