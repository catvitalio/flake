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

  protonWoSteamDeck = mkWrappedProton {
    name = "proton-cachyos-steamdeck0";
    displayName = "Proton CachyOS";
    exports = {
      SteamDeck = "0";
      SDL_GAMECONTROLLER_IGNORE_DEVICES = "0x3537/0x1022"; # for ea app the original variable is too long, ignore only the gamepads i have
    };
  };
in
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

  nixpkgs.overlays = [ nix-gaming-edge.overlays.mesa-git ];

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
          "${protonWoSteamDeck.steamcompattool}"
        ];
        PROTON_FSR4_UPGRADE = "1";
      };
    };
  };

  programs.steam.extraCompatPackages = [
    protonWoSteamDeck
  ];

  environment.systemPackages = with pkgs; [
    pkgs.wget
    pkgs.codex
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
}
