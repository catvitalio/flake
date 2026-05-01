{
  lib,
  config,
  pkgs,
  nix-gaming-edge,
  ...
}:

let
  cfg = config.my.wrappedProton;
  protonCachyos = nix-gaming-edge.packages.${pkgs.system}.proton-cachyos;
  mkWrappedProton = import ../lib/mk-wrapped-proton.nix { inherit lib pkgs protonCachyos; };
in
{
  options.my.wrappedProton = {
    enable = lib.mkEnableOption "wrapped Proton (Proton CachyOS) with env fixes";

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Resulting wrapped proton package (internal).";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = "proton-custom";
      description = "Internal compat tool name.";
    };

    displayName = lib.mkOption {
      type = lib.types.str;
      default = "Proton Custom";
      description = "Displayed name in Steam compatibility tools list.";
    };

    exports = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra env vars exported by the proton launcher wrapper.";
      example = {
        SteamDeck = "0";
        SteamGenericControllers = "";
        PROTON_FSR4_UPGRADE = "1";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      wrapped = mkWrappedProton {
        inherit (cfg) name displayName exports;
      };
    in
    {
      my.wrappedProton.package = wrapped;

      jovian.steam.environment.STEAM_EXTRA_COMPAT_TOOLS_PATHS = lib.concatStringsSep ":" [
        "${wrapped.steamcompattool}"
      ];

      programs.steam.extraCompatPackages = [ wrapped ];
    }
  );
}
