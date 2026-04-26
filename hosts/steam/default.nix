{
  lib,
  pkgs,
  config,
  secrets,
  nix-gaming-edge,
  ...
}:

let
  protonCachyos = nix-gaming-edge.packages.${pkgs.system}.proton-cachyos;
  mkWrappedProton = import ./mk-wrapped-proton.nix {
    inherit lib pkgs protonCachyos;
  };

  protonWithFixes = mkWrappedProton {
    name = "proton-cachyos-steamdeck0";
    displayName = "Proton CachyOS";
    exports = {
      SteamDeck = "0"; # turn off steamdeck mode
      SteamGenericControllers = ""; # cut unneccessary long env var (ea app fix)
      PROTON_FSR4_UPGRADE = "1";
    };
  };
in
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
  ];

  networking = {
    hostName = "steam";
    networkmanager.enable = true;
    networkmanager.insertNameservers = [ "10.100.0.2" ];
    interfaces.enp14s0.wakeOnLan.enable = true;
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
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = lib.concatStringsSep ":" [
          "${protonWithFixes.steamcompattool}"
        ];
      };
    };
  };

  programs.steam.extraCompatPackages = [ protonWithFixes ];

  environment.systemPackages = with pkgs; [
    pkgs.wget
    pkgs.codex
    pkgs.firefox
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
}
