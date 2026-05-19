{
  description = "NixOS configuration flake";

  nixConfig = {
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix.url = "github:ryantm/agenix";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    nix-gaming-edge = {
      url = "github:powerofthe69/nix-gaming-edge";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    secrets = {
      url = "git+ssh://git@github.com/catvitalio/secrets.git";
      flake = false;
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
      nix-cachyos-kernel,
      nix-gaming-edge,
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
      nixosModules = {
        cachyosKernel = import ./modules/cachyos-kernel.nix;
        wrappedProton = import ./modules/wrapped-proton.nix;
      };

      nixosConfigurations = {
        homelab = mkHost nixpkgs {
          modules = [ ./hosts/homelab ];
        };

        steam = mkHost nixpkgs-unstable {
          specialArgs = {
            inherit nix-cachyos-kernel nix-gaming-edge;
          };
          modules = [
            disko.nixosModules.disko
            jovian.nixosModules.default
            self.nixosModules.cachyosKernel
            ./hosts/steam
          ];
        };
      };
    };
}
