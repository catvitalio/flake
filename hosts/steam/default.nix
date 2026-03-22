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
    networkmanager.insertNameservers = [ "10.100.0.2" ];
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
      environment = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin.steamcompattool}";
        PROTON_FSR4_UPGRADE = "1";
      };
    };
  };

  programs.steam.extraCompatPackages = with pkgs; [ proton-ge-bin ];

  environment.systemPackages = with pkgs; [
    pkgs.wget
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
