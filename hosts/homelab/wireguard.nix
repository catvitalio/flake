{ config, ... }:

{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.2/24" ];
    privateKeyFile = config.age.secrets.wireguardKey.path;
    peers = [
      {
        publicKey = "mL2pYNjMdCjaW1CCFTVxeKUIbjlv3/Bg5vw0yfEO6H8=";
        allowedIPs = [ "10.100.0.0/24" ];
        endpoint = "192.168.1.1:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  networking.firewall.trustedInterfaces = [ "wg0" ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
