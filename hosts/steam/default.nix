{
  config,
  pkgs,
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
    ../../profiles/generations.nix
    ./wake/tv.nix
    ./wake/controller.nix
    ./lact.nix
    ./decky
    ./hardware.nix
    ./secureboot.nix
    ./disko.nix
    ./gamescope.nix
    ./windows.nix
    ./wireguard.nix
  ];

  networking = {
    hostName = "steam";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  services.desktopManager.gnome.enable = true;

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
    steamos.enableHdmiCecIntegration = false;
    steam = {
      enable = true;
      autoStart = true;
      user = config.my.user;
      desktopSession = "gnome";
      environment = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-cachyos_x86_64_v3}";
        LOW_LATENCY_LAYER = "1";
      };
    };
  };

  my.nightlyBuild.steam.updater = {
    enable = true;
    builderHost = "192.168.1.2";
    user = config.my.user;
    steamosButton = true;
  };

  hardware.graphics.extraPackages = [ pkgs.low-latency-layer ];

  environment.systemPackages = with pkgs; [
    wget
    firefox
  ];

  system.stateVersion = "26.05";
}
