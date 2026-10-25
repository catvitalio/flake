{ config, pkgs, ... }:

let
  domain = "assistant.catvitalio.com";
  address = "127.0.0.1";
  port = 8123;
in
{
  services.home-assistant = {
    enable = true;

    extraComponents = [
      "default_config"
      "met"
      "radio_browser"
    ];

    customComponents = [
      (pkgs.callPackage ../../pkgs/yandex-station.nix { })
    ];

    config = {
      homeassistant = {
        name = "Home";
        time_zone = config.time.timeZone;
        unit_system = "metric";
        external_url = "https://${domain}";
      };

      http = {
        server_host = address;
        server_port = port;
        use_x_forwarded_for = true;
        trusted_proxies = [ address ];
      };

      default_config = { };
    };
  };

  my.reverseProxy.${domain} = {
    proxyPass = "http://${address}:${toString port}";
    proxyWebsockets = true;
  };
}
