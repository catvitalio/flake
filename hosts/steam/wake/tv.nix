{
  config,
  pkgs,
  secrets,
  ...
}:

let
  tvIp = "192.168.1.36";
in
{
  age.secrets.tvMac = {
    file = "${secrets}/tvMac.age";
  };

  environment.systemPackages = with pkgs; [
    android-tools
    wakeonlan
  ];

  systemd.services.tv-wake = {
    description = "Wake TV and switch HDMI input on resume";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    partOf = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStop = pkgs.writeShellScript "tv-wake" ''
        tvMac=$(cat ${config.age.secrets.tvMac.path})
        ${pkgs.wakeonlan}/bin/wakeonlan -i ${tvIp} $tvMac
        ${pkgs.android-tools}/bin/adb disconnect ${tvIp}:5555 || true
        for i in $(${pkgs.coreutils}/bin/seq 1 60); do
          ${pkgs.coreutils}/bin/timeout 1 ${pkgs.android-tools}/bin/adb connect ${tvIp}:5555 >/dev/null 2>&1 || true
          status=$(${pkgs.android-tools}/bin/adb devices | ${pkgs.gnugrep}/bin/grep "${tvIp}:5555" | ${pkgs.gawk}/bin/awk '{print $2}')
          echo "tv-wake: attempt $i: $status"
          [ "$status" = "device" ] && break
          [ "$status" = "offline" ] && ${pkgs.android-tools}/bin/adb disconnect ${tvIp}:5555 >/dev/null 2>&1 || true
        done
        ${pkgs.android-tools}/bin/adb shell am force-stop com.tcl.tvinput || true
        ${pkgs.coreutils}/bin/timeout 10 ${pkgs.android-tools}/bin/adb shell am start \
          -a android.intent.action.VIEW \
          -d 'content://android.media.tv/passthrough/com.tcl.tvinput%2F.TvPassThroughService%2FHW15' || true
      '';
    };
  };
}
