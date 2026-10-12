{
  config,
  pkgs,
  shoehorn,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "L+ ${config.jovian.decky-loader.stateDir}/plugins/Shoehorn - - - - ${
      shoehorn.packages.${pkgs.stdenv.hostPlatform.system}.default
    }"
  ];
}
