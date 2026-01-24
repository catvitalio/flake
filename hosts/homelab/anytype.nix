{ ... }:

{
  virtualisation.oci-containers.containers.anytype = {
    image = "ghcr.io/grishy/any-sync-bundle:1.2.1-2025-12-10";
    ports = [
      "33010:33010"
      "33020:33020"
    ];
    volumes = [ "/var/lib/anytype:/data" ];
    environment = {
      ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS = "10.100.0.2";
    };
  };
}
