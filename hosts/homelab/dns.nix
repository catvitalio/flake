{
  lib,
  ...
}:

let
  constants = import ./constants.nix;
  censoredDomains = import ./censoredDomains { inherit lib; };
  censoredAddresses = lib.concatMap (domain: [
    "/${domain}/${constants.xray.censoredIp}"
    "/${domain}/::"
  ]) censoredDomains;
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
        "77.88.8.8"
        "77.88.8.1"
      ];
      address = censoredAddresses ++ [
        "/nextcloud.catvitalio.com/${constants.wireguard.address}"
        "/bitwarden.catvitalio.com/${constants.wireguard.address}"
      ];
      cache-size = 10000;
    };
  };
}
