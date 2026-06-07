{
  config,
  ...
}:

{
  networking.wireguard.interfaces.wg0 = {
    ips = [
      "10.100.0.5/24"
      "fd00:100::5/64"
    ];
    privateKeyFile = config.age.secrets.wireguardSteamKey.path;
    peers = [
      {
        publicKey = "mL2pYNjMdCjaW1CCFTVxeKUIbjlv3/Bg5vw0yfEO6H8=";
        allowedIPs = [
          "10.100.0.0/24"
          "fd00:100::/64"
        ];
        endpoint = "192.168.1.1:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
