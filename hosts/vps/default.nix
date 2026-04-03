{ lib, ... }:
{
  imports = [
    ../../dots/common
    ../../dots/locale
    ../../dots/ssh
    ./hardware.nix
    ./disko.nix
  ];

  networking = {
    hostName = "vps";
    useDHCP = false;
    firewall.enable = true;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    interfaces.enp0s3.ipv4.addresses = [
      {
        address = "89.169.34.190";
        prefixLength = 32;
      }
    ];
    defaultGateway = {
      address = "10.0.0.1";
      interface = "enp0s3";
    };
    interfaces.enp0s3.ipv4.routes = [
      {
        address = "10.0.0.1";
        prefixLength = 32;
      }
    ];
  };

  boot.loader.grub.devices = [ "/dev/vda" ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwQVt0KOWb/JYBB+3l0MpVH6U+DZk7wct0rcgrwykYHFyXcKZLMEFveYavsjN7XlNkl4ipl5Bz8w3zFU6Szp4UHuSI+rDMCT1EMi2Gv6a2y32+8P9/F7KDkWrDkQr9BLbMQ3V06KTTnIB1+gRtJClqCoU/bBzHbQyJHB1k3/psBK7TzjLzlloJm7PLBsBZmuneRgxBAFXGRV5g2FujYqVYR/xTjBoNtyNmp9Jpya9cVj2cX2rNea8d34bDZCzyYwrltFKMKCtIJ/vOnTXQ5pjhKvVd8MrNsSdgqOoqiqe+vS+LAG/Z6/K/JWvFvh92ms5RZiGW5yN6oC4tm7iSpH8DA+dfm4XyksNsqbU1MjcQ1BvjYove7YW9mJ1rVawHbVRK1T4m2Cs61lAq2W5YKbc4xY6qaaJcfR79l/p9hAT/3EFFaC2KKG0IhC1hGGMd4/x+ks7gl4utga+wG7gQDKstFeTAMMBn6lPjpZnrU+dfEugfmToX5Pa33HpjV1Q1Mj8= v@Vitalys-MacBook-Air.local"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.11";
}
