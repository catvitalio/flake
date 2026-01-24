rebuild host="homelab" *args:
    sudo nixos-rebuild switch --flake .#{{ host }} {{ args }}

backup *args:
    restic-important {{ args }}
