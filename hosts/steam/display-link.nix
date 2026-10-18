{ lib, pkgs, ... }:

let
  connector = "DP-2";
  sampleInterval = 5;

  snapshot = pkgs.writeShellScript "display-link-snapshot" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils ]}
    mode=$1

    linkDir=""
    for dir in /sys/kernel/debug/dri/*/${connector}; do
      [ -d "$dir" ] && linkDir=$dir && break
    done
    if [ -z "$linkDir" ]; then
      echo "$mode: no debugfs entry for ${connector}"
      exit 0
    fi

    auxDev=""
    for dev in /sys/class/drm_dp_aux_dev/*; do
      case "$(readlink -f "$dev/device" 2>/dev/null)" in
        *-${connector}) auxDev=/dev/''${dev##*/} ;;
      esac
    done

    dpcd() {
      [ -n "$auxDev" ] || return 0
      od -An -tx1 -N"$2" -j "$1" "$auxDev" 2>/dev/null | tr -s ' \n' ' '
    }

    state=""
    for attr in link_settings phy_settings dsc_clock_en dsc_bits_per_pixel \
                dsc_slice_width dsc_slice_height output_bpc; do
      value=$(tr -d '\0' < "$linkDir/$attr" 2>/dev/null | tr -s ' \n' ' ')
      state="$state$attr:''${value% } | "
    done
    state="$state"lane_status:$(dpcd $((0x202)) 3)"| errors:$(dpcd $((0x210)) 8)"

    printf '%s: %s\n' "$mode" "$state"
  '';

  watch = pkgs.writeShellScript "display-link-watch" ''
    PATH=${lib.makeBinPath [ pkgs.coreutils ]}
    previous=""
    while :; do
      current=$(${snapshot} sample)
      if [ "$current" != "$previous" ]; then
        printf '%s\n' "$current"
        previous=$current
      fi
      sleep ${toString sampleInterval}
    done
  '';
in
{
  systemd.services.display-link = {
    description = "Record the ${connector} link state after resume";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
    ];
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "multi-user.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${snapshot} resume";
    };
  };

  systemd.services.display-link-watch = {
    description = "Record every change of the ${connector} link state";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = watch;
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
