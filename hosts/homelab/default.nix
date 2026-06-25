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
    ../../modules/amneziawg-server.nix
    ./age.nix
    ./hardware.nix
    ./wireguard.nix
    ./amneziawg.nix
    ./singbox.nix
    ./dns.nix
    ./homepage.nix
    ./nextcloud.nix
    ./vaultwarden.nix
    ./restic.nix
  ];

  system.stateVersion = "25.11";

  networking = {
    hostName = "homelab";
    networkmanager.enable = true;
    firewall.enable = true;
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
