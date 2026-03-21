rebuild host *args:
    sudo nixos-rebuild switch --flake .#{{ host }} {{ args }}

update-flake *args:
    nix flake update {{ args }}

update host:
    just update-flake
    just rebuild {{ host }}

update-secrets:
    nix flake lock --update-input secrets

backup *args:
    restic-important {{ args }}
