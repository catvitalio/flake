{ ... }:

let
  constants = import ./constants.nix;
in
{
  virtualisation.oci-containers.containers.anytype = {
    image = "ghcr.io/grishy/any-sync-bundle:1.3.0-2026-01-31";
    ports = [
      "33010:33010"
      "33020:33020"
    ];
    volumes = [ "/var/lib/anytype:/data" ];
    environment = {
      ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS = constants.wireguard.address;
    };
  };
}
