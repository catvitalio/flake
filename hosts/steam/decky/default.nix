{ config, pkgs, ... }:

let
  pluginScriptDeps = pkgs.buildEnv {
    name = "decky-plugin-deps";
    paths = with pkgs; [
      bash
      coreutils
      findutils
      flatpak
      gawk
      gnugrep
      gnused
      jq
      psmisc
      python3
      util-linux
      wget
    ];
  };

  user = config.my.user;
  home = config.users.users.${user}.home;
  owner = "${user} ${config.users.users.${user}.group}";

  steamRoot = "${home}/.local/share/Steam";
  bashFallbackPath = "/no-such-path";
  deckyStateDir = "${home}/homebrew";
in
{
  imports = [ ./unifideck.nix ];

  jovian.decky-loader = {
    enable = true;
    inherit user;
    stateDir = deckyStateDir;
    extraPackages = with pkgs; [
      bash
      python3
      flatpak
    ];
  };

  services.envfs = {
    enable = true;
    extraFallbackPathCommands = "ln -sf ${pluginScriptDeps}/bin/* $out/";
  };

  services.flatpak.enable = true;

  systemd.tmpfiles.rules = [
    "f ${steamRoot}/.cef-enable-remote-debugging 0644 ${owner} -"
    "L+ ${bashFallbackPath} - - - - ${pluginScriptDeps}/bin"
    "d ${deckyStateDir} 0755 ${owner} -"
    "d ${deckyStateDir}/plugins 0755 ${owner} -"
    "L+ ${steamRoot}/compatibilitytools.d/proton-cachyos - - - - ${pkgs.proton-cachyos_x86_64_v3}"
  ];

  nixpkgs.overlays = [
    (_: prev: {
      steam = prev.steam.override { extraPkgs = p: [ p.flatpak ]; };
    })
  ];
}
