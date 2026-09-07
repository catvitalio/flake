{
  config,
  pkgs,
  secrets,
  ...
}:

let
  tvIp = "192.168.1.36";
  adb = "${pkgs.android-tools}/bin/adb";
  coreutils = pkgs.coreutils;

  # Runs inside systemd-suspend.service — earliest possible hook on resume,
  # before sleep.target deactivates. Sends WoL immediately so TV has maximum
  # boot time before ADB tries to connect.
  sleepHook = pkgs.writeShellScript "tv-wol-hook" ''
    # $1 = pre|post  $2 = suspend|hibernate|hybrid-sleep|suspend-then-hibernate
    [ "$1" = "post" ] || exit 0
    tvMac=$(${coreutils}/bin/cat ${config.age.secrets.tvMac.path})
    ${pkgs.wakeonlan}/bin/wakeonlan -i 192.168.1.255 "$tvMac"
  '';

  # Runs later (after sleep.target deactivates) once network is likely up.
  # By then TV has had time to boot; ADB connect should succeed quickly.
  wakeScript = pkgs.writeShellScript "tv-wake" ''
    # Fast path: TV already connected (didn't fully sleep)
    status=$(${adb} devices | ${pkgs.gnugrep}/bin/grep "${tvIp}:5555" | ${pkgs.gawk}/bin/awk '{print $2}')
    if [ "$status" != "device" ]; then
      ${adb} disconnect ${tvIp}:5555 >/dev/null 2>&1 || true
      for i in $(${coreutils}/bin/seq 1 30); do
        out=$(${coreutils}/bin/timeout 2 ${adb} connect ${tvIp}:5555 2>&1)
        echo "tv-wake: attempt $i: $out"
        case "$out" in
          *"connected to"*) break ;;
          *"offline"*)
            ${adb} disconnect ${tvIp}:5555 >/dev/null 2>&1 || true
            ${coreutils}/bin/sleep 1
            ;;
          *) ${coreutils}/bin/sleep 1 ;;
        esac
      done
    fi

    ${adb} -s ${tvIp}:5555 shell input keyevent 224 || true
    ${coreutils}/bin/sleep 1
    ${adb} -s ${tvIp}:5555 shell am start \
      -a android.intent.action.VIEW \
      -d 'content://android.media.tv/passthrough/com.tcl.tvinput%2F.TvPassThroughService%2FHW15' || true
  '';
in
{
  age.secrets.tvMac = {
    file = "${secrets}/tvMac.age";
  };

  environment.systemPackages = with pkgs; [
    android-tools
    wakeonlan
  ];

  # Early WoL hook — fires the moment the system resumes, not waiting for sleep.target
  environment.etc."systemd/system-sleep/tv-wol" = {
    mode = "0755";
    source = sleepHook;
  };

  # Keeps ADB connection alive so wake script hits the fast path
  systemd.services.tv-adb-keepalive = {
    description = "Keep ADB connection to TV alive";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "30s";
      ExecStart = pkgs.writeShellScript "tv-adb-keepalive" ''
        while true; do
          ${adb} connect ${tvIp}:5555 >/dev/null 2>&1 || true
          ${coreutils}/bin/sleep 30
        done
      '';
    };
  };

  systemd.services.tv-wake = {
    description = "Switch TV HDMI input on resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = wakeScript;
    };
  };
}
