{ config, lib, ... }:

{
  options.my.generationLimit = lib.mkOption {
    type = lib.types.ints.positive;
    default = 10;
    description = "How many system generations to keep.";
  };

  config = {
    boot.loader.systemd-boot.configurationLimit = config.my.generationLimit;

    nix.gc = {
      automatic = true;
      dates = "daily";
    };

    systemd.services.nix-gc.serviceConfig.ExecStartPre = ''
      ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system \
        --delete-generations +${toString config.my.generationLimit}
    '';
  };
}
