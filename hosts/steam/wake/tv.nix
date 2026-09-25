{ pkgs, ... }:

let
  connector = "DP-2";
  physAddr = "1.0.0.0";
  cecCtl = "${pkgs.v4l-utils}/bin/cec-ctl";
  cecClient = "${pkgs.libcec}/bin/cec-client";
  coreutils = pkgs.coreutils;
  grep = "${pkgs.gnugrep}/bin/grep";

  sleepHook = pkgs.writeShellScript "tv-cec-hook" ''
    [ "$1" = post ] || exit 0
    ${pkgs.util-linux}/bin/setsid ${pkgs.runtimeShell} -c '
      for i in $(${coreutils}/bin/seq 1 10); do
        [ -e /dev/cec0 ] && break
        ${coreutils}/bin/sleep 0.1
      done
      ${cecCtl} -d /dev/cec0 --playback --osd-name steam >/dev/null 2>&1 || true
      ${cecCtl} -d /dev/cec0 --to 0 --image-view-on >/dev/null 2>&1 || true
      ${cecCtl} -d /dev/cec0 --active-source phys-addr=${physAddr} >/dev/null 2>&1 || true
    ' >/dev/null 2>&1 < /dev/null &
  '';

  wakeScript = pkgs.writeShellScript "tv-wake" ''
    tv_is_on() {
      ${cecCtl} -d /dev/cec0 --to 0 --give-device-power-status --timeout 2000 2>/dev/null \
        | ${grep} -q "pwr-state: on"
    }

    rebuild_tunnel() {
      echo 1 > /sys/kernel/debug/dri/1/${connector}/trigger_hotplug 2>/dev/null || true
      ${coreutils}/bin/sleep 2
      ${cecCtl} -d /dev/cec0 --playback --osd-name steam >/dev/null 2>&1 || true
    }

    ${cecCtl} -d /dev/cec0 --playback --osd-name steam >/dev/null 2>&1 || true

    for round in 1 2 3; do
      [ $round = 1 ] || rebuild_tunnel
      for i in $(${coreutils}/bin/seq 1 8); do
        ${cecCtl} -d /dev/cec0 --to 0 --image-view-on >/dev/null 2>&1 || true
        ${cecCtl} -d /dev/cec0 --active-source phys-addr=${physAddr} >/dev/null 2>&1 || true
        ${coreutils}/bin/sleep 2
        if tv_is_on; then
          echo "tv-wake: TV on after round $round, attempt $i"
          # The TV reports itself on a moment before it will honour
          # active-source, so keep nudging the input.
          for j in 1 2 3; do
            ${coreutils}/bin/sleep 2
            ${cecCtl} -d /dev/cec0 --active-source phys-addr=${physAddr} >/dev/null 2>&1 || true
          done
          exit 0
        fi
      done
      echo "tv-wake: no reply in round $round, re-probing the connector"
    done

    echo "tv-wake: gave up, TV did not answer over CEC"
    exit 1
  '';

  watchScript = pkgs.writeShellScript "tv-standby-watch" ''
    ${cecClient} -m -d 8 2>&1 \
      | ${grep} --line-buffered -E ">> 0[0-9a-f]:36" \
      | while read -r line; do
          echo "tv-standby-watch: TV went to standby, suspending"
          ${pkgs.systemd}/bin/systemctl suspend
          ${coreutils}/bin/sleep 30
        done
  '';
in
{
  environment.etc."systemd/system-sleep/tv-cec" = {
    mode = "0755";
    source = sleepHook;
  };

  systemd.services.tv-wake = {
    description = "Turn the TV on and select this input after resume";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = wakeScript;
    };
  };

  systemd.services.tv-standby-watch = {
    description = "Suspend when the TV broadcasts CEC standby";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = watchScript;
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
