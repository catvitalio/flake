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

    secrets = {
      url = "git+ssh://git@github.com/catvitalio/secrets.git";
      flake = false;
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    steam-config-nix = {
      url = "github:different-name/steam-config-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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
      chaotic,
      lanzaboote,
      steam-config-nix,
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
            ./modules/nightly-build.nix
            ./modules/sidestore-ike-reflector.nix
            ./modules/ike-vpn.nix
            ./hosts/homelab
          ];
        };

        steam = mkHost nixpkgs-unstable {
          modules = [
            disko.nixosModules.disko
            jovian.nixosModules.default
            chaotic.nixosModules.default
            lanzaboote.nixosModules.lanzaboote
            steam-config-nix.nixosModules.default
            ./hosts/steam
          ];
        };
      };
    };
}
