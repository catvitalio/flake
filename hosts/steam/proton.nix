{ pkgs, ... }:

{
  jovian.steam.environment = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-cachyos_x86_64_v3}";
  };
}
