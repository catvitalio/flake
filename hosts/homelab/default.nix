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
    ../../profiles/nginx.nix
    ./age.nix
    ./disko.nix
    ./hardware.nix
    ./wireguard.nix
    ./singbox.nix
    ./dns.nix
    ./homepage.nix
    ./vaultwarden.nix
    ./restic.nix
  ];

  my.reverseProxy.ip = "10.100.0.1";

  my.nightlyBuild.steam = {
    substituters = [ "https://nyx-cache.chaotic.cx/" ];
    trustedPublicKeys = [ "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=" ];
  };

  my.ikeVpn = import "${secrets}/ike.nix" // {
    enable = true;
    caCert = "${secrets}/ike-ca.pem";
    lanIp = "192.168.1.2";
    wanInterface = "eno1";
    pool = "10.101.0.0/24";
    sharedPoolRange = "10.101.0.1-10.101.0.10";
  };

  my.sidestoreIkeReflector = {
    enable = true;
    phoneIp = "10.101.0.11";
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
