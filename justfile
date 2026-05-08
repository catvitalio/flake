deploy host:
    nix run nixpkgs#nixos-rebuild -- \
        switch \
        --flake .#{{host}} \
        --target-host root@{{host}} \
        --build-host root@{{host}}

update-input input:
    nix flake update {{input}}

update-secrets: (update-input "secrets")
