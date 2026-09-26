{ pkgs, ... }:

let
  connector = "DP-2";
  coreutils = pkgs.coreutils;

  script = pkgs.writeShellScript "display-link" ''
    dir=""
    for _ in $(${coreutils}/bin/seq 1 40); do
      for d in /sys/kernel/debug/dri/*/${connector}; do
        if [ -d "$d" ]; then
          dir="$d"
          break 2
        fi
      done
      ${coreutils}/bin/sleep 0.25
    done
    if [ -z "$dir" ]; then
      echo "display-link: no debugfs entry for ${connector}"
      exit 0
    fi
    echo "display-link: using $dir"

    echo "4 0x1e" > "$dir/link_settings" 2>/dev/null || true
    ${coreutils}/bin/sleep 1

    for f in link_settings phy_settings dsc_clock_en dsc_bits_per_pixel \
             dsc_slice_width dsc_slice_height output_bpc; do
      printf '%s: %s\n' "$f" \
        "$(${coreutils}/bin/tr -d '\0' < "$dir/$f" 2>/dev/null | ${coreutils}/bin/tr '\n' ' ')"
    done
  '';
in
{
  systemd.services.display-link = {
    description = "Pin the DP link rate to HBR3 and record the link state";
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
      ExecStart = script;
    };
  };
}
