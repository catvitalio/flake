{
  description = "NixOS configuration flake";

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
      nix-gaming-edge,
      secrets,
      ...
    }:
    {
      nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit self secrets nix-gaming-edge;
          agenix-cli = agenix.packages.x86_64-linux.default;
        };
        modules = [
          agenix.nixosModules.default
          ./hosts/homelab
        ];
      };

      nixosConfigurations.steam = nixpkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit self secrets nix-gaming-edge;
          agenix-cli = agenix.packages.x86_64-linux.default;
        };
        modules = [
          agenix.nixosModules.default
          disko.nixosModules.disko
          jovian.nixosModules.default
          ./hosts/steam
        ];
      };
    };
}
