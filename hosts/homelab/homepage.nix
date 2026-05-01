{
  lib,
  config,
  ...
}:

let
  domain = "dash.catvitalio.com";
in
{
  services.homepage-dashboard = {
    enable = true;
    allowedHosts = domain;

    settings = {
      title = "Homelab";
      favicon = "https://${domain}/favicon.ico";
      theme = "dark";
      color = "slate";
      background = {
        blur = "sm";
        brightness = 0.6;
        opacity = 15;
      };
    };

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          uptime = true;
          cputemp = true;
          network = "eno1";
          refresh = 3000;
        };
      }
    ];

    services = [
      {
        "Services" = [
          {
            "AdGuard Home" = {
              href = "https://adguard.catvitalio.com";
              description = "DNS filtering";
            };
          }
          {
            "Nextcloud" = {
              href = "https://nextcloud.catvitalio.com";
              description = "Files";
            };
          }
          {
            "Vaultwarden" = {
              href = "https://bitwarden.catvitalio.com";
              description = "Passwords";
            };
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.homepage-dashboard.listenPort}";
      proxyWebsockets = true;
    };
  };

  security.acme.certs.${domain} = {
    dnsProvider = "timewebcloud";
    environmentFile = config.age.secrets.acmeEnv.path;
    reloadServices = [ "nginx" ];
  };

  services.dnsmasq.settings.address = lib.mkAfter [
    "/${domain}/${config.my.wireguard.ipv4Address}"
  ];
}
