{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:

{
  imports = [
    ../../dots/age
    ../../dots/common
    ../../dots/locale
    ../../dots/ssh
    ../../dots/users
    ../../dots/nvim
    ../../dots/wireguard
    ./hardware.nix
    ./disko.nix
    ./singbox.nix
    ./proton.nix
  ];

  networking = {
    hostName = "steam";
    networkmanager.enable = true;
    networkmanager.insertNameservers = [ "10.100.0.2" ];
    interfaces.enp11s0.wakeOnLan.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.enable = false;
    wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.5/32" ];
      privateKeyFile = config.age.secrets.wireguardSteamKey.path;
    };
  };

  services = {
    desktopManager.plasma6.enable = true;
  };

  age.secrets.wireguardSteamKey = {
    file = "${secrets}/wireguardSteamKey.age";
    mode = "400";
    owner = "root";
    group = "root";
  };

  jovian = {
    hardware.has.amd.gpu = true;
    hardware.amd.gpu.enableBacklightControl = false;
    steamos.useSteamOSConfig = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "v";
      desktopSession = "plasma";
    };
  };

  environment.systemPackages = with pkgs; [
    pkgs.wget
    pkgs.codex
    pkgs.firefox
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
}
