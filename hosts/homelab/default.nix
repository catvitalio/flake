{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../dots/age
    ../../dots/nginx
    ../../dots/fish
    ../../dots/locale
    ../../dots/nvim
    ../../dots/ssh
    ../../dots/users
    ../../dots/common
    ./hardware.nix
    ./vpn.nix
    ./dns.nix
    ./nextcloud.nix
    ./vaultwarden.nix
    ./anytype.nix
    ./restic.nix
  ];

  system.stateVersion = "25.11";

  networking = {
    hostName = "homelab";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.enable = true;
  };
  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    pkgs.wget
    pkgs.htop
    pkgs.git
    pkgs.gcc
    pkgs.nodejs
    pkgs.claude-code
    pkgs.just
    pkgs.nixfmt-rfc-style
    pkgs.nixd
    pkgs.iproute2
    pkgs.tree
    pkgs.dig
    pkgs.pciutils
    pkgs.intel-gpu-tools
    pkgs.fastfetch
    pkgs.tcpdump
  ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
