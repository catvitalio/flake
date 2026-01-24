rebuild host="homelab" *args:
    sudo nixos-rebuild switch --flake .#{{ host }}

backup *args:
    restic-important {{ args }}
