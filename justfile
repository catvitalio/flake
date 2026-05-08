deploy host:
    nix run nixpkgs#nixos-rebuild -- \
        switch \
        --flake .#{{host}} \
        --target-host v@{{ host }} \
        --build-host v@{{ host }} \
        --sudo \
        --ask-sudo-password

