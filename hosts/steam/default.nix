{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:

{
  imports = [
    ../../profiles/age.nix
    ../../profiles/common.nix
    ../../profiles/locale.nix
    ../../profiles/ssh.nix
    ../../profiles/nvim.nix
    ../../profiles/users.nix
    ./hardware.nix
    ./disko.nix
    ./singbox.nix
    ./proton.nix
    ./wireguard.nix
  ];

  networking = {
    hostName = "steam";
    networkmanager.enable = true;
    networkmanager.insertNameservers = [ "10.100.0.2" ];
    interfaces.enp11s0.wakeOnLan.enable = true;
    firewall.enable = false;
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
    wget
    firefox
  ];

  system.stateVersion = "26.05";
}
