{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../dots/age
    ../../dots/common
    ../../dots/fish
    ../../dots/locale
    ../../dots/ssh
    ../../dots/users
    ../../dots/nvim
    ./hardware.nix
    ./disko.nix
  ];

  networking = {
    hostName = "steam";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.enable = false;
  };

  services = {
    desktopManager.plasma6.enable = true;
  };

  jovian = {
    hardware = {
      has.amd.gpu = true;
      amd.gpu.enableBacklightControl = false;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "v";
      desktopSession = "plasma";
    };
    steamos.useSteamOSConfig = true;
  };

  environment.systemPackages = with pkgs; [
    pkgs.wget
    pkgs.hidapi
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
