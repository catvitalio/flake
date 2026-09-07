{ pkgs, ... }:

# The machine kept waking itself at night (e.g. the TV toggling its HDMI link
# reaches the GPU through the SWUS/SWDS PCIe bridges), after which a flaky
# gamescope resume crashed the session and Jovian rebooted the box — killing
# whatever game was suspended. Disable every ACPI wakeup source except the
# power button and the keyboard/mouse USB controller chain:
# GPP7 (00:02.1) -> UP00 (05:00.0) -> DP60 (06:0c.0) -> XH00 (10:00.0).
{
  systemd.services.disable-stray-wakeup-sources = {
    description = "Disable ACPI wakeup sources except power button and keyboard/mouse USB path";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "disable-stray-wakeup-sources" ''
        for dev in SWUS SWDS GPP0 GPP1 GPP8 GP17 XHC0 XHC1 XHC2 \
                   DP00 DP20 DP28 DP30 DP38 DP40 DP48 DP50 DP58 DP68; do
          if ${pkgs.gnugrep}/bin/grep -q "^$dev.*\*enabled" /proc/acpi/wakeup; then
            echo "$dev" > /proc/acpi/wakeup
          fi
        done
      '';
    };
  };
}
