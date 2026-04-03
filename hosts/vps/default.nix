{ lib, secrets, ... }:

let
  vps = import "${secrets}/vps.nix";
in
{
  imports = [
    ../../dots/common
    ../../dots/locale
    ../../dots/ssh
    ../../dots/users
    ../../dots/age
    ./disko.nix
  ];

  networking = {
    hostName = "vps";
    useDHCP = false;
    firewall.enable = true;
    nameservers = [
      vps.dns.first
      vps.dns.second
    ];
    interfaces.eth0.ipv4.addresses = [
      {
        address = vps.ip;
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = vps.gateway;
      interface = "eth0";
    };
  };

  boot = {
    loader = {
      grub = {
        enable = true;
        useOSProber = false;
        devices = lib.mkForce [ ];
        mirroredBoots = lib.mkForce [
          {
            path = "/boot";
            devices = [ "/dev/vda" ];
          }
        ];
      };
    };
    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "ahci"
      "sd_mod"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.11";
}
