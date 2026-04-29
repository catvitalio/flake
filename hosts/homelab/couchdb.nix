{ lib, config, ... }:

let
  domain = "couchdb.catvitalio.com";
  address = "127.0.0.1";
  port = 5984;
  constants = import ./constants.nix;
in
{
  services.couchdb = {
    enable = true;
    adminUser = "obsidian";
    bindAddress = address;
    extraConfigFiles = [ config.age.secrets.couchdbPass.path ];
    inherit port;
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
