{ ... }:

{
  environment.interactiveShellInit = ''
    if [ -n "$SSH_TTY" ] && [ -z "$SSH_SLEEP_INHIBIT" ]; then
      export SSH_SLEEP_INHIBIT=1
      exec /run/current-system/sw/bin/systemd-inhibit \
        --what=sleep \
        --why="Active SSH session" \
        "$SHELL" -l
    fi
  '';
}
