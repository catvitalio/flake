{ lib, pkgs, ... }:

let
  connector = "DP-2";
  chromaFormat = "yuv422";

  formats = [
    "yuv420"
    "yuv422"
    "yuv444"
  ];

  forceChroma = pkgs.writeShellScript "force-${chromaFormat}" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils ]}

    dir=""
    for _ in $(seq 1 40); do
      for candidate in /sys/kernel/debug/dri/*/${connector}; do
        [ -d "$candidate" ] && dir=$candidate && break 2
      done
      sleep 0.25
    done
    if [ -z "$dir" ]; then
      echo "no debugfs entry for ${connector}"
      exit 0
    fi

    ${lib.concatMapStringsSep "\n    " (format: ''echo 0 > "$dir/force_${format}_output"'') formats}
    echo 1 > "$dir/force_${chromaFormat}_output"

    if [ "$(tr -d '\0' < "$dir/dsc_clock_en")" != 0 ]; then
      echo 1 > "$dir/trigger_hotplug"
      sleep 2
    fi

    echo "${chromaFormat}: dsc_clock_en=$(tr -d '\0' < "$dir/dsc_clock_en") link=$(tr -d '\0' < "$dir/link_settings" | tr -s ' \n' ' ')"
  '';
in
{
  systemd.services.force-chroma = {
    description = "Drive ${connector} as ${chromaFormat} so DSC stays out of the path";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = forceChroma;
    };
  };
}
