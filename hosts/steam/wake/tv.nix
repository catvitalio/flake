{
  config,
  pkgs,
  secrets,
  ...
}:

let
  tvIp = "192.168.1.36";
  nic = "enp12s0";
  adb = "${pkgs.android-tools}/bin/adb";
  coreutils = pkgs.coreutils;


  # Runs later (after sleep.target deactivates) once network is likely up.
  # By then TV has had time to boot; ADB connect should succeed quickly.
  wakeScript = pkgs.writeShellScript "tv-wake" ''
    # Wait for our own NIC before sending anything: on resume r8169 drops the
    # link and renegotiates for ~3s, so a magic packet fired earlier (as the
    # sleep hook used to do) is silently lost and the TV never starts waking.
    for i in $(${coreutils}/bin/seq 1 60); do
      [ "$(${coreutils}/bin/cat /sys/class/net/${nic}/carrier 2>/dev/null)" = 1 ] && break
      ${coreutils}/bin/sleep 0.25
    done
    echo "tv-wake: ${nic} carrier up after $i check(s)"

    tvMac=$(${coreutils}/bin/cat ${config.age.secrets.tvMac.path})
    ${pkgs.wakeonlan}/bin/wakeonlan -i 192.168.1.255 "$tvMac" >/dev/null 2>&1 || true

    # Always reconnect, never trust "adb devices" here: after a resume the
    # local adb server still reports the pre-suspend state while the socket to
    # the TV is long dead, and the first command then hangs ~17s on a TCP
    # timeout. A forced reconnect costs milliseconds.
    ${adb} disconnect ${tvIp}:5555 >/dev/null 2>&1 || true
    for i in $(${coreutils}/bin/seq 1 60); do
      if [ $(( i % 4 )) = 0 ]; then
        ${pkgs.wakeonlan}/bin/wakeonlan -i 192.168.1.255 "$tvMac" >/dev/null 2>&1 || true
      fi
      ${coreutils}/bin/timeout 1 ${adb} connect ${tvIp}:5555 >/dev/null 2>&1 || true
      state=$(${adb} devices | ${pkgs.gnugrep}/bin/grep "${tvIp}:5555" | ${pkgs.gawk}/bin/awk '{print $2}')
      [ "$state" = device ] && break
      ${coreutils}/bin/sleep 0.25
    done
    echo "tv-wake: adb ready after $i attempt(s): ''${state:-none}"

    # KEYCODE_WAKEUP is idempotent, so fire it before asking anything — that
    # skips a round trip and starts the panel waking as early as possible.
    # Then confirm it took: a keyevent sent a moment too early is ignored.
    for i in $(${coreutils}/bin/seq 1 5); do
      ${coreutils}/bin/timeout 5 ${adb} -s ${tvIp}:5555 shell input keyevent 224 >/dev/null 2>&1 || true
      ${coreutils}/bin/sleep 1
      wake=$(${coreutils}/bin/timeout 5 ${adb} -s ${tvIp}:5555 shell "dumpsys power | grep -m1 mWakefulness=" 2>/dev/null | ${coreutils}/bin/tr -d '\r')
      echo "tv-wake: $wake"
      case "$wake" in *Awake*) break ;; esac
    done

    ${adb} -s ${tvIp}:5555 shell am start \
      -a android.intent.action.VIEW \
      -d 'content://android.media.tv/passthrough/com.tcl.tvinput%2F.TvPassThroughService%2FHW15' || true

    # The TV locks its picture profile to whatever signal is present at tune
    # time; right after wake the HDMI link is often still negotiating (no
    # ALLM/HDR/VRR yet), which picks the wrong profile. Re-tune once the
    # signal has settled — re-tuning on a stable signal keeps the profile.
    ${coreutils}/bin/sleep 10
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
