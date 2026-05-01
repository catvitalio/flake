{
  self,
  secrets,
  agenix,
  system,
}:

let
  agenix-cli = agenix.packages.${system}.default;
in
nixpkgsInput:
{
  modules,
  specialArgs ? { },
}:
nixpkgsInput.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit self secrets agenix-cli;
  }
  // specialArgs;
  modules = [ agenix.nixosModules.default ] ++ modules;
}
