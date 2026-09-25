{ pkgs, ... }:

let
  connector = "DP-2";
  cecClient = "${pkgs.libcec}/bin/cec-client";
  coreutils = pkgs.coreutils;
  systemctl = "${pkgs.systemd}/bin/systemctl";
  runtimeDir = "/run/tv-cec";
  fifo = "${runtimeDir}/cmd";
  selfStandby = "${runtimeDir}/self-standby";
  readyFlag = "${runtimeDir}/ready";

  waitForDevice = ''
    for _ in $(${coreutils}/bin/seq 1 40); do
      [ -e /dev/cec0 ] && break
      ${coreutils}/bin/sleep 0.25
    done
    if [ ! -e /dev/cec0 ]; then
      echo 1 > /sys/kernel/debug/dri/1/${connector}/trigger_hotplug 2>/dev/null || true
      ${coreutils}/bin/sleep 2
    fi
  '';

  daemon = pkgs.writeShellScript "tv-cec" ''
    ${waitForDevice}
    [ -e /dev/cec0 ] || { echo "tv-cec: /dev/cec0 never appeared"; exit 1; }

    ${coreutils}/bin/mkdir -p ${runtimeDir}
    ${coreutils}/bin/rm -f ${fifo}
    ${coreutils}/bin/mkfifo -m 0600 ${fifo}
    exec 3<> ${fifo}

    ${coreutils}/bin/rm -f ${readyFlag}

    ${cecClient} -d 8 -t p -o steam < ${fifo} 2>&1 \
      | while IFS= read -r line; do
          case "$line" in
            *"waiting for input"*)
              ${coreutils}/bin/touch ${readyFlag}
              continue
              ;;
            *">> 0"?":36"*) ;;
            *) continue ;;
          esac
          if [ -f ${selfStandby} ] \
            && [ $(( $(${coreutils}/bin/date +%s) \
                     - $(${coreutils}/bin/stat -c %Y ${selfStandby}) )) -lt 90 ]; then
            echo "tv-cec: standby echoes our own request, not suspending"
            continue
          fi
          echo "tv-cec: TV went to standby, suspending"
          ${systemctl} suspend
          ${coreutils}/bin/sleep 30
        done
  '';

  wakeScript = pkgs.writeShellScript "tv-cec-wake" ''
    ${coreutils}/bin/rm -f ${fifo} ${readyFlag}
    ${systemctl} restart tv-cec.service

    for _ in $(${coreutils}/bin/seq 1 40); do
      [ -p ${fifo} ] && break
      ${coreutils}/bin/sleep 0.25
    done
    [ -p ${fifo} ] || { echo "tv-cec-wake: no command fifo"; exit 1; }

    ${coreutils}/bin/rm -f ${selfStandby}

    for _ in $(${coreutils}/bin/seq 1 100); do
      [ -f ${readyFlag} ] && break
      ${coreutils}/bin/sleep 0.1
    done

    for _ in $(${coreutils}/bin/seq 1 7); do
      ${coreutils}/bin/timeout 5 ${pkgs.runtimeShell} -c "printf 'on 0\nas\n' > ${fifo}" || true
      ${coreutils}/bin/sleep 0.5
    done
  '';

  sleepScript = pkgs.writeShellScript "tv-cec-sleep" ''
    [ -p ${fifo} ] || exit 0
    ${coreutils}/bin/touch ${selfStandby}
    ${coreutils}/bin/timeout 5 ${pkgs.runtimeShell} -c "printf 'standby 0\n' > ${fifo}" || true
    ${coreutils}/bin/sleep 2
  '';
in
{
  systemd.services.tv-cec = {
    description = "Persistent CEC device for the TV";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = daemon;
      Restart = "always";
      RestartSec = "10s";
    };
  };

  systemd.services.tv-cec-sleep = {
    description = "Put the TV into standby before suspending";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = sleepScript;
    };
  };

  systemd.services.tv-cec-wake = {
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
}
