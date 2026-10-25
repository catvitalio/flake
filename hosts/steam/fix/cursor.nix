{
  nixpkgs.overlays = [
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
