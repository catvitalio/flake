{
  lib,
  config,
  ...
}:

let
  cfg = config.my.wireguard;
  defaultPeers = [
    {
      publicKey = "mL2pYNjMdCjaW1CCFTVxeKUIbjlv3/Bg5vw0yfEO6H8=";
      allowedIPs = [ "10.100.0.0/24" ];
      endpoint = "192.168.1.1:51820";
      persistentKeepalive = 25;
    }
  ];

  effectiveIps =
    if cfg.ips != [ ] then
      cfg.ips
    else if cfg.ipv4Address != null then
      [ "${cfg.ipv4Address}/${toString cfg.ipv4PrefixLength}" ]
    else
      [ ];
in
{
  options.my.wireguard = {
    enable = lib.mkEnableOption "WireGuard interface configuration";

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "WireGuard interface name.";
    };

    ipv4Address = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Convenience IPv4 address for the interface; used to derive ips when ips is empty.";
      example = "10.100.0.2";
    };

    ipv4PrefixLength = lib.mkOption {
      type = lib.types.int;
      default = 32;
      description = "Prefix length used when deriving ips from ipv4Address.";
      example = 24;
    };

    ips = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "IP addresses assigned to the interface.";
      example = [ "10.100.0.5/32" ];
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the private key file for the interface.";
    };

    peers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = defaultPeers;
      description = "List of peer attribute sets (as expected by networking.wireguard.interfaces.<name>.peers).";
    };

    firewallTrusted = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to add the interface to networking.firewall.trustedInterfaces.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireguard.interfaces.${cfg.interfaceName} = {
      ips = effectiveIps;
      inherit (cfg) peers;
    }
    // lib.optionalAttrs (cfg.privateKeyFile != null) {
      inherit (cfg) privateKeyFile;
    };

    networking.firewall.trustedInterfaces = lib.mkIf cfg.firewallTrusted [ cfg.interfaceName ];
  };
}
