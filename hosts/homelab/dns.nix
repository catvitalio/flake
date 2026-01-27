{
  lib,
  ...
}:

let
  makeDomainPair = domain: [
    "/${domain}/10.100.0.100"
    "/${domain}/::"
  ];
  censoredDomains = import ./censoredDomains { inherit lib; };
  censoredPairs = lib.flatten (map makeDomainPair censoredDomains);
in
{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      listen-address = "0.0.0.0";
      bind-interfaces = true;
      port = 53;
      server = [
        "77.88.8.8"
        "77.88.8.1"
      ];
      address = censoredPairs ++ [
        "/nextcloud.catvitalio.com/10.100.0.2"
        "/bitwarden.catvitalio.com/10.100.0.2"
      ];
      cache-size = 10000;
    };
  };
}
