{
  config,
  lib,
  pkgs,
  ...
}:

let
  home = config.users.users.${config.my.user}.home;
  applications = "${home}/.local/share/applications";
  hideGameEntries = pkgs.writeShellScript "hide-steam-game-entries" ''
    PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnugrep
      ]
    }

    shopt -s nullglob
    for entry in ${applications}/*.desktop; do
      grep -q 'steam://rungameid/' "$entry" || continue
      [ "$(grep -c '^NoDisplay=true$' "$entry")" = 1 ] && continue

      work=$(mktemp "$entry.XXXXXX")
      trap 'rm -f "$work"' EXIT
      grep -v '^NoDisplay=' "$entry" > "$work"
      printf 'NoDisplay=true\n' >> "$work"
      chmod --reference="$entry" "$work"
      mv -f "$work" "$entry"
      trap - EXIT
      echo "hid ''${entry##*/}"
    done
  '';
in
{
  systemd.user.services.hide-steam-game-entries = {
    description = "Keep Steam's per-game launchers out of the app grid";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = hideGameEntries;
    };
  };

  systemd.user.paths.hide-steam-game-entries = {
    description = "Watch for launchers Steam adds for newly installed games";
    wantedBy = [ "default.target" ];
    pathConfig = {
      PathChanged = applications;
      TriggerLimitIntervalSec = "5s";
    };
  };
}
