{ config, ... }:

let
  wgInterface = "wg0";
  constants = import ./constants.nix;
in
{
  networking.wireguard.interfaces.${wgInterface} = {
    ips = [ "${constants.wireguard.address}/24" ];
    privateKeyFile = config.age.secrets.wireguardKey.path;
  };
  networking.firewall.trustedInterfaces = [ wgInterface ];
}
