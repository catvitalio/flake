{ pkgs, nix-gaming-edge, ... }:

let
  protonCachyos = nix-gaming-edge.packages.${pkgs.system}.proton-cachyos;
in
{
  jovian.steam.environment = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${protonCachyos.steamcompattool}";
  };
}
