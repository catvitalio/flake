{ lib, ... }:

{
  # Steam's cursor stays 16px under GNOME at scale 2, because the FHS env has no
  # cursor theme and Xcursor never learns the scale. Preloading libXcursor makes
  # it read the theme, and Adwaita has to be inside the env to be found.
  nixpkgs.overlays = lib.mkAfter [
    (_: prev: {
      jovianPackages = prev.jovianPackages // {
        steam = prev.jovianPackages.steam.override (old: {
          extraPkgs = p: (old.extraPkgs or (_: [ ])) p ++ [ p.adwaita-icon-theme ];
          extraProfile = (old.extraProfile or "") + ''
            case "$XDG_CURRENT_DESKTOP" in
              *GNOME*) export LD_PRELOAD=libXcursor.so.1 ;;
            esac
          '';
        });
      };
    })
  ];
}
