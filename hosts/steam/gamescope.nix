{ pkgs, lib, ... }:

let
  width = 3840;
  height = 2160;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      gamescope-session = prev.gamescope-session.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          substituteInPlace $out/lib/steamos/gamescope-session \
            --replace-fail "-w 1280 -h 800" "-w ${toString width} -h ${toString height}"
        '';
      });
    })
  ];
}
