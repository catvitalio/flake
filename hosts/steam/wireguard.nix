{
  config,
  devices,
  ...
}:

{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${devices.steam.ip}/32" ];
    privateKeyFile = config.age.secrets.wireguardSteamKey.path;
    mtu = 1420;
    peers = [
      {
        inherit (devices.homelab) publicKey;
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "192.168.1.2:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
