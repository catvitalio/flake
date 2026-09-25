{
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
    ./wake/tv.nix
    ./wake/controller.nix
    ./updater.nix
    ./hardware.nix
    ./secureboot.nix
    ./disko.nix
    ./proton.nix
    ./gamescope.nix
    ./lact.nix
    ./fans.nix
    ./wireguard.nix
  ];

  networking = {
    hostName = "steam";
    networkmanager.enable = true;
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
    steamos.enableHdmiCecIntegration = false;
    steam = {
      enable = true;
      autoStart = true;
      user = "v";
      desktopSession = "plasma";
      environment = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-cachyos_x86_64_v3}";
        ENABLE_LAYER_MESA_ANTI_LAG = "1";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    firefox
  ];

  system.stateVersion = "26.05";
}
