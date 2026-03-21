{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    pkgs.nixfmt
    pkgs.nixd
    pkgs.just
    pkgs.tree
    pkgs.git
    pkgs.htop
    pkgs.fastfetch
  ];
}
