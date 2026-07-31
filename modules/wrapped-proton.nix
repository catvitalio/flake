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
  mkWrappedProton = import ../lib/mk-wrapped-proton.nix { inherit lib pkgs; };
  enabledWrappers = lib.filterAttrs (_: wrapper: wrapper.enable) cfg;
  wrappedPackages = lib.mapAttrs (
    wrapperName: wrapper:
    mkWrappedProton {
      inherit (wrapper) protonPackage displayName exports;
      name = wrapperName;
    }
  ) enabledWrappers;
in
{
  options.my.wrappedProton = lib.mkOption {
    default = { };
    description = "Wrapped Proton (Proton CachyOS) instances with env fixes.";
    type = lib.types.attrsOf (
      lib.types.submodule (
        { ... }:
        {
          options = {
            enable = lib.mkEnableOption "wrapped Proton (Proton CachyOS) with env fixes";

            protonPackage = lib.mkOption {
              type = lib.types.package;
              default = protonCachyos;
              defaultText = lib.literalExpression "nix-gaming-edge.packages.\${pkgs.system}.proton-cachyos";
              description = "Base Proton package whose steamcompattool will be wrapped.";
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
        }
      )
    );
  };

  config = lib.mkIf (enabledWrappers != { }) {
    jovian.steam.environment.STEAM_EXTRA_COMPAT_TOOLS_PATHS = lib.concatStringsSep ":" (
      map (wrapped: "${wrapped.steamcompattool}") (lib.attrValues wrappedPackages)
    );

    programs.steam.extraCompatPackages = lib.attrValues wrappedPackages;
  };
}
