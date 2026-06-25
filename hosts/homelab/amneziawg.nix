{ config, ... }:

{
  services.amneziawg-server = {
    enable = true;
    interface = "awg0";
    port = 13231;
    serverIp = "10.100.0.1/24";
    subnet = "10.100.0.0/24";
    privateKeyFile = config.age.secrets.wireguardKey.path;
    peers = [
      {
        publicKey = "b4cc1bd43fb3444b8cb703c85d787737c1b3ff53aaa1b6c4f374048031993d66";
        allowedIp = "10.100.0.10";
      }
    ];
  };
}
