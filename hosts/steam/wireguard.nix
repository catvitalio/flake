{
  config,
  ...
}:

{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.13/32" ];
    privateKeyFile = config.age.secrets.wireguardSteamKey.path;
    peers = [
      {
        publicKey = "TkdsA32GzAWl2GTESZgJeoTwIodaDvSzYTCuvy9oRRk=";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
        endpoint = "192.168.1.118:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
