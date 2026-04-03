{
  lib,
  pkgs,
  ...
}:

let
  constants = import ./constants.nix;
in
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
    ../../dots/wireguard
    ./age.nix
    ./hardware.nix
    ./vpn.nix
    ./dns.nix
    ./nextcloud.nix
    ./vaultwarden.nix
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
  programs.fish.shellAliases = {
    codex = "env https_proxy=http://${constants.wireguard.address}:${toString constants.singBox.httpPort} codex";
  };

  environment.systemPackages = with pkgs; [
    pkgs.wget
    pkgs.nodejs
    pkgs.codex
    pkgs.iproute2
    pkgs.dig
    pkgs.pciutils
    pkgs.intel-gpu-tools
    pkgs.tcpdump
  ];

  nix.settings = {
    trusted-public-keys = [
      "hysteria.cachix.org-1:zAG2qV/akrj0TPOf28gxWTDj57f8SuYjqjHw2u38vZI="
    ];
    substituters = [
      "https://hysteria.cachix.org"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
