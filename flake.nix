{
  description = "NixOS configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    agenix.url = "github:ryantm/agenix";
    disko.url = "github:nix-community/disko";

    secrets = {
      url = "git+ssh://git@github.com/catvitalio/secrets.git";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      agenix,
      disko,
      secrets,
      ...
    }:
    let
      system = "x86_64-linux";
      mkHost = import ./lib/mk-host.nix {
        inherit
          self
          secrets
          agenix
          system
          ;
      };
    in
    {
      nixosConfigurations = {
        homelab = mkHost nixpkgs {
          modules = [
            disko.nixosModules.disko
            ./lib/reverse-proxy.nix
            ./hosts/homelab
          ];
        };

      };
    };
}
