{
  config,
  self,
  ...
}:

{
  imports = [ self.nixosModules.wireguard ];

  my.wireguard = {
    enable = true;
    ipv4Address = "10.100.0.5";
    ipv4PrefixLength = 32;
    privateKeyFile = config.age.secrets.wireguardSteamKey.path;
  };
}
