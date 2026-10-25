{
  pkgs,
  secrets,
  devices,
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
    ../../profiles/nginx.nix
    ./age.nix
    ./disko.nix
    ./hardware.nix
    ./wireguard.nix
    ./singbox.nix
    ./dns.nix
    ./homepage.nix
    ./home-assistant.nix
    ./vaultwarden.nix
    ./restic.nix
  ];

  my.reverseProxy.ip = devices.homelab.ip;

  my.nightlyBuild.steam.builder = {
    enable = true;
    substituters = [ "https://nyx-cache.chaotic.cx/" ];
    trustedPublicKeys = [ "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=" ];
  };

  my.sidestoreReflector = {
    enable = true;
    phoneIp = devices.iphone.ip;
  };

  system.stateVersion = "26.05";

  networking = {
    hostName = "homelab";
    networkmanager = {
      enable = true;
      unmanaged = [ "eno1" ];
    };
    firewall.enable = true;
    interfaces.eno1.ipv4.addresses = [
      {
        address = "192.168.1.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "192.168.1.1";
      interface = "eno1";
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    iproute2
    dig
    pciutils
    intel-gpu-tools
    tcpdump
  ];

}
