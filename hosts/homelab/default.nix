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
