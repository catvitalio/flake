rebuild host="homelab" *args:
    sudo nixos-rebuild switch --flake .#{{ host }} {{ args }}

update-flake:
    nix flake update

update host="homelab":
    just update-flake
    just rebuild {{ host }}

update-secrets:
    nix flake lock --update-input secrets

backup *args:
    restic-important {{ args }}
