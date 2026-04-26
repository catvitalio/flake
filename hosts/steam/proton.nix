{
  lib,
  pkgs,
  nix-gaming-edge,
  ...
}:

let
  protonCachyos = nix-gaming-edge.packages.${pkgs.system}.proton-cachyos;
  mkWrappedProton = import ./utils/mkWrappedProton.nix {
    inherit lib pkgs protonCachyos;
  };
  protonWithFixes = mkWrappedProton {
    name = "proton-cachyos-steamdeck0";
    displayName = "Proton CachyOS";
    exports = {
      SteamDeck = "0"; # turn off steamdeck mode
      SteamGenericControllers = ""; # cut unneccessary long env var (ea app fix)
      PROTON_FSR4_UPGRADE = "1";
    };
  };
in
{
  jovian.steam.environment = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = lib.concatStringsSep ":" [
      "${protonWithFixes.steamcompattool}"
    ];
  };
  programs.steam.extraCompatPackages = [ protonWithFixes ];
}
