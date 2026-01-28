let
  constants = import ./constants.nix;
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
      cache-size = 10000;
    };
  };
}
