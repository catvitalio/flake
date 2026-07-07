{
  pkgs,
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
    ../../profiles/nginx.nix
    ./age.nix
    ./disko.nix
    ./hardware.nix
    ./wireguard.nix
    ./singbox.nix
    ./dns.nix
    ./homepage.nix
    ./nextcloud.nix
    ./vaultwarden.nix
    ./restic.nix
  ];

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
