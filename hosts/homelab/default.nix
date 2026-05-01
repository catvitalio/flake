{
  lib,
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
    ./hardware.nix
    ./wireguard.nix
    ./singbox.nix
    ./dns.nix
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
  virtualisation = {
    docker.enable = true;
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    wget
    nodejs
    codex
    iproute2
    dig
    pciutils
    intel-gpu-tools
    tcpdump
  ];

}
