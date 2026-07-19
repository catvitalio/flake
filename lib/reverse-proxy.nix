{ lib, config, ... }:
let
  serviceType = lib.types.submodule {
    options = {
      proxyPass = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      proxyWebsockets = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      locations = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
    };
  };
in
{
  options.my.reverseProxy = lib.mkOption {
    default = { };
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf serviceType;
      options.ip = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config =
    let
      svcs = removeAttrs config.my.reverseProxy [ "ip" ];
      ip = config.my.reverseProxy.ip;
    in
    {
      services.nginx.virtualHosts = lib.mapAttrs (domain: svc: {
        useACMEHost = domain;
        forceSSL = true;
        locations = lib.mkMerge [
          (lib.optionalAttrs (svc.proxyPass != null) {
            "/" =
              { proxyPass = svc.proxyPass; }
              // lib.optionalAttrs svc.proxyWebsockets { proxyWebsockets = true; };
          })
          svc.locations
        ];
      }) svcs;

      security.acme.certs = lib.mapAttrs (_: _: {
        dnsProvider = "timewebcloud";
        environmentFile = config.age.secrets.acmeEnv.path;
        reloadServices = [ "nginx" ];
      }) svcs;

      services.dnsmasq.settings.address = lib.mkAfter (
        map (domain: "/${domain}/${ip}") (lib.attrNames svcs)
      );
    };
}
