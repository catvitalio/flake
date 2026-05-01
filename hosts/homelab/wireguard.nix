{ config, ... }:

let
  constants = import ./constants.nix;
in
{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${constants.wireguard.address}/24" ];
    privateKeyFile = config.age.secrets.wireguardKey.path;
  };
}
