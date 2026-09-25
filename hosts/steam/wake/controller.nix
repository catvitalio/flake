{ pkgs, ... }:

let
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
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="28de", ATTR{idProduct}=="1304", TEST=="power/wakeup", ATTR{power/wakeup}="enabled", RUN+="${enableWakeupChain} /sys%p"
  '';
}
