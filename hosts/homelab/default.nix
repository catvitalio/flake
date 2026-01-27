{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../dots/age
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
  systemd.services.nix-daemon.environment = {
    https_proxy = "socks5://192.168.1.1:1080";
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

  services.nginx = {
    enable = true;
    group = "acme";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "catvitalio@gmail.com";
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
