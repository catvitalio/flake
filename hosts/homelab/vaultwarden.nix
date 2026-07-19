{ ... }:

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

  my.reverseProxy.${domain}.proxyPass = "http://${address}:${toString port}";
}
