{ lib, pkgs, ... }:

{
  imports = [
    ../../dots/age
    ../../dots/common
    ../../dots/fish
    ../../dots/locale
    ../../dots/ssh
    ../../dots/users
    ./hardware.nix
    ./disko.nix
  ];

  system.stateVersion = "25.11";

  networking = {
    hostName = "steam-machine";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.enable = true;
  };

  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  jovian = {
    steamos.useSteamOSConfig = true;
    hardware.has.amd.gpu = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "v";
      desktopSession = "plasma";
    };
  };

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    pkgs.git
    pkgs.wget
    pkgs.htop
    pkgs.fastfetch
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
