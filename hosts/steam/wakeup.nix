{ pkgs, ... }:

# The machine kept waking itself at night (e.g. the TV toggling its HDMI link
# reaches the GPU through the SWUS/SWDS PCIe bridges), after which a flaky
# gamescope resume crashed the session and Jovian rebooted the box — killing
# whatever game was suspended. Disable every ACPI wakeup source except the
# power button and the two paths that should wake the machine:
#   keyboard/mouse: GPP7 (00:02.1) -> UP00 (05:00.0) -> DP60 (06:0c.0) -> XH00 (10:00.0)
#   Steam Controller Puck: GP17 (00:08.1) -> XHC1 (13:00.4) -> usb3 -> hubs -> puck
let
  # A device can only wake the system if every USB hop above it may signal
  # remote wakeup too, so walk from the controller up to the PCI bridge.
  # Runs on hotplug, which also covers re-plugging the dongle elsewhere.
  enableWakeupChain = pkgs.writeShellScript "usb-wakeup-chain" ''
    dev=$1
    while [ -n "$dev" ] && [ "$dev" != "/sys/devices" ] && [ "$dev" != "/" ]; do
      if [ -f "$dev/power/wakeup" ]; then
        echo enabled > "$dev/power/wakeup" 2>/dev/null || true
      fi
      dev=$(${pkgs.coreutils}/bin/dirname "$dev")
    done
  '';
in
{
  # Wake from sleep on the Steam button, as in ublue-os/bazzite#4881.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="28de", ATTR{idProduct}=="1304", TEST=="power/wakeup", ATTR{power/wakeup}="enabled", RUN+="${enableWakeupChain} /sys%p"
  '';

  systemd.services.disable-stray-wakeup-sources = {
    description = "Disable ACPI wakeup sources except power button, keyboard/mouse and Steam Controller";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "disable-stray-wakeup-sources" ''
        for dev in SWUS SWDS GPP0 GPP1 GPP8 XHC0 XHC2 \
                   DP00 DP20 DP28 DP30 DP38 DP40 DP48 DP50 DP58 DP68; do
          if ${pkgs.gnugrep}/bin/grep -q "^$dev.*\*enabled" /proc/acpi/wakeup; then
            echo "$dev" > /proc/acpi/wakeup
          fi
        done
      '';
    };
  };
}
