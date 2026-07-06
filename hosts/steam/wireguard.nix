{
  config,
  pkgs,
  ...
}:

{
  boot.extraModulePackages = with config.boot.kernelPackages; [ amneziawg ];
  environment.systemPackages = with pkgs; [ amneziawg-tools ];

  networking.wg-quick.interfaces.awg0 = {
    type = "amneziawg";
    address = [ "10.100.0.13/32" ];
    dns = [ "10.100.0.1" ];
    mtu = 1280;
    privateKeyFile = config.age.secrets.wireguardSteamKey.path;

    extraOptions = {
      Jc = 4;
      Jmin = 40;
      Jmax = 70;
      S1 = 0;
      S2 = 0;
      H1 = 1;
      H2 = 2;
      H3 = 3;
      H4 = 4;
    };

    peers = [
      {
        publicKey = "TkdsA32GzAWl2GTESZgJeoTwIodaDvSzYTCuvy9oRRk=";
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        endpoint = "192.168.1.118:47891";
        persistentKeepalive = 25;
      }
    ];
  };
}
