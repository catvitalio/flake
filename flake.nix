{
  description = "NixOS configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    agenix.url = "github:ryantm/agenix";
    disko.url = "github:nix-community/disko";
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";
    secrets = {
      url = "git+ssh://git@github.com/catvitalio/secrets.git";
      flake = false;
    };
    disko.inputs.nixpkgs.follows = "nixpkgs";
    jovian.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      agenix,
      disko,
      jovian,
      secrets,
    }:
    {
      nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit self secrets;
          agenix-cli = agenix.packages.x86_64-linux.default;
        };
        modules = [
          agenix.nixosModules.default
          ./hosts/homelab
        ];
      };
      nixosConfigurations.steam = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit self secrets;
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
