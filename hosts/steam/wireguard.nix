{
  config,
  devices,
  ...
}:

{
  networking.nameservers = [ devices.homelab.ip ];

  networking.wireguard.interfaces.wg0 = {
    ips = [ "${devices.steam.ip}/32" ];
    privateKeyFile = config.age.secrets.wireguardSteamKey.path;
    mtu = 1420;
    peers = [
      {
        inherit (devices.homelab) publicKey;
        allowedIPs = [ "0.0.0.0/0" ];
        endpoint = "${devices.homelab.lanIp}:${toString devices.homelab.wireguardPort}";
        persistentKeepalive = 25;
      }
    ];
  };
}
