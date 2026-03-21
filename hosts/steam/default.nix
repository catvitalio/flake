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
    ../../dots/fish
    ../../dots/locale
    ../../dots/ssh
    ../../dots/users
    ../../dots/nvim
    ../../dots/wireguard
    ./hardware.nix
    ./disko.nix
  ];

  networking = {
    hostName = "steam";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.enable = false;
    nameservers = [ "10.100.0.2" ];
    wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.5/24" ];
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
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
