{ config, ... }:

{
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.2/32" ];
      privateKeyFile = config.age.secrets.wireguardKey.path;

      peers = [
        {
          publicKey = "uYi32L/K0nkQT0GpPBcuGsW475FipH/0JfomRrWMFRk=";
          allowedIPs = [
            "10.100.0.0/24"
          ];
          endpoint = "192.168.1.1:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
