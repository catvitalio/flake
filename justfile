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

vps-install ip:
    ssh root@{{ ip }} 'mkdir -p /persist/ssh'
    scp /persist/ssh/id_ed25519 root@{{ ip }}:/persist/ssh/id_ed25519
    nix run github:nix-community/nixos-anywhere -- --flake .#vps root@{{ ip }} --show-trace
