{
  description = "NixOS configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    disko.url = "github:nix-community/disko";

    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-gaming-edge = {
      url = "github:powerofthe69/nix-gaming-edge";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    secrets = {
      url = "git+ssh://git@github.com/catvitalio/secrets.git";
      flake = false;
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      agenix,
      disko,
      jovian,
      nix-gaming-edge,
      chaotic,
      lanzaboote,
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
            ./modules/reverse-proxy.nix
            ./hosts/homelab
          ];
        };

        steam = mkHost nixpkgs-unstable {
          specialArgs = {
            inherit nix-gaming-edge;
          };
          modules = [
            disko.nixosModules.disko
            jovian.nixosModules.default
            chaotic.nixosModules.default
            lanzaboote.nixosModules.lanzaboote
            ./hosts/steam
          ];
        };
      };
    };
}
