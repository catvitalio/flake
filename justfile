rebuild host="homelab" *args:
    sudo nixos-rebuild switch --flake .#{{ host }} {{ args }}

update secrets:
    nix flake lock --update-input secrets

backup *args:
    restic-important {{ args }}
