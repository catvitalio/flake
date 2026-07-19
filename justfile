deploy host:
    nix run nixpkgs#nixos-rebuild -- \
        switch \
        --flake .#{{host}} \
        --target-host root@{{host}} \
        --build-host root@{{host}}

deploy-homelab: (deploy "homelab")

update input="":
    nix flake update {{input}}

update-secrets: (update "secrets")

clean host:
    ssh root@{{host}} 'nix-collect-garbage -d'
