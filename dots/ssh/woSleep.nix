{ pkgs, ... }:

let
  sshInhibitSleep = pkgs.writeShellScript "ssh-inhibit-sleep" ''
    has_ssh_session() {
      for sid in $(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
        remote=$(${pkgs.systemd}/bin/loginctl show-session "$sid" -p Remote --value 2>/dev/null)
        service=$(${pkgs.systemd}/bin/loginctl show-session "$sid" -p Service --value 2>/dev/null)
        state=$(${pkgs.systemd}/bin/loginctl show-session "$sid" -p State --value 2>/dev/null)

        if [ "$remote" = "yes" ] && [ "$service" = "sshd" ] && [ "$state" != "closing" ]; then
          return 0
        fi
      done

      return 1
    }

    while true; do
      if has_ssh_session; then
        ${pkgs.systemd}/bin/systemd-inhibit \
          --what=idle:sleep:handle-lid-switch \
          --mode=block \
          --who=sshd \
          --why="Active SSH session" \
          ${pkgs.coreutils}/bin/sleep 60
      else
        ${pkgs.coreutils}/bin/sleep 15
      fi
    done
  '';
in
{
  systemd.services.ssh-inhibit-sleep = {
    description = "Prevent sleep while SSH sessions are active";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = sshInhibitSleep;
      Restart = "always";
      RestartSec = 5;
    };
  };
}
