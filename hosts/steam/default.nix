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
in
{
  imports = [
    nix-gaming-edge.nixosModules.mesa-git
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

  drivers.mesa-git = {
    enable = true;
    cacheCleanup = {
      enable = true;
      protonPackage = protonCachyos;
    };
    steamOrphanCleanup.enable = true;
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
    decky-loader.enable = true;
    steam = {
      enable = true;
      autoStart = true;
      user = "v";
      desktopSession = "plasma";
      environment = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${protonCachyos.steamcompattool}";
        PROTON_FSR4_UPGRADE = "1";
      };
    };
  };

  systemd.services.steam-cef-debug = lib.mkIf config.jovian.decky-loader.enable {
    description = "Create Steam CEF debugging file";
    serviceConfig = {
      Type = "oneshot";
      User = config.jovian.steam.user;
      ExecStart = "/bin/sh -c 'mkdir -p ~/.steam/steam && [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true'";
    };
    wantedBy = [ "multi-user.target" ];
  };

  programs.steam.extraCompatPackages = [ protonCachyos ];

  environment.systemPackages = with pkgs; [
    pkgs.wget
    pkgs.codex
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
}
