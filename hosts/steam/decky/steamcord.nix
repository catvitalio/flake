{
  config,
  lib,
  pkgs,
  ...
}:
let
  gstreamerPackages = map (lib.getOutput "out") (
    with pkgs;
    [
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      libnice
      pipewire
    ]
  );

  overlayPackages = map (lib.getOutput "out") (
    with pkgs;
    [
      glib
      gobject-introspection
      gtk3
      atk
      gdk-pixbuf
      pango
      harfbuzz
    ]
  );
in
{
  environment.systemPackages = [ pkgs.vesktop ];

  jovian.decky-loader.extraPackages = with pkgs; [
    procps
    pulseaudio
  ];

  systemd.services.decky-loader.environment = {
    GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPath "lib/gstreamer-1.0" gstreamerPackages;
    GI_TYPELIB_PATH = lib.makeSearchPath "lib/girepository-1.0" (gstreamerPackages ++ overlayPackages);
  };

  systemd.tmpfiles.rules = [
    "L+ ${config.jovian.decky-loader.stateDir}/plugins/Steamcord - - - - ${
      pkgs.callPackage ../../../pkgs/steamcord.nix { }
    }"
  ];
}
