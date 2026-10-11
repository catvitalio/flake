{ config, pkgs, ... }:

{
  jovian.decky-loader = {
    extraPackages = with pkgs; [
      curl
      util-linux
      xdg-user-dirs
      xdotool
    ];
    extraPythonPackages = ps: [ ps.rpds-py ];
  };

  systemd.tmpfiles.rules = [
    "L+ ${config.jovian.decky-loader.stateDir}/plugins/Unifideck - - - - ${
      pkgs.callPackage ../../../pkgs/unifideck.nix { }
    }"
  ];
}
