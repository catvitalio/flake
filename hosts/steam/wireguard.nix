{
  config,
  devices,
  ...
}:

{
  my.wireguardClient = {
    enable = true;
    address = "${devices.steam.ip}/32";
    privateKeyFile = config.age.secrets.wireguardSteamKey.path;
    dns = devices.homelab.ip;
    peer = {
      inherit (devices.homelab) publicKey;
      endpoint = "${devices.homelab.lanIp}:${toString devices.homelab.wireguardPort}";
    };
    failover.enable = true;
  };
}
