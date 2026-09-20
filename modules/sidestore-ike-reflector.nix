{ lib, config, ... }:

# SideStore loopback reflector for a phone connected over IKEv2. iOS forbids
# an app from connecting to the device's own RemotePairing service, so
# SideStore talks to a virtual device address instead; this NAT pair bounces
# those connections straight back to the phone through the tunnel, replacing
# StosVPN. IPsec has no interface, so traffic is matched by XFRM policy; the
# phone must have a fixed pool address (see hosts/homelab/ike.nix).
let
  cfg = config.my.sidestoreIkeReflector;
in
{
  options.my.sidestoreIkeReflector = {
    enable = lib.mkEnableOption "SideStore loopback reflector for an IKEv2 phone";
    phoneIp = lib.mkOption {
      type = lib.types.str;
      description = "Fixed IKEv2 pool address of the phone.";
    };
    sidestoreIp = lib.mkOption {
      type = lib.types.str;
      default = "10.7.0.1";
      description = "Virtual device address SideStore connects to.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.extraCommands = ''
      iptables -t nat -A PREROUTING -m policy --dir in --pol ipsec -s ${cfg.phoneIp} -d ${cfg.sidestoreIp} -j DNAT --to-destination ${cfg.phoneIp}
      iptables -t nat -A POSTROUTING -s ${cfg.phoneIp} -d ${cfg.phoneIp} -j SNAT --to-source ${cfg.sidestoreIp}
    '';
    networking.firewall.extraStopCommands = ''
      iptables -t nat -D PREROUTING -m policy --dir in --pol ipsec -s ${cfg.phoneIp} -d ${cfg.sidestoreIp} -j DNAT --to-destination ${cfg.phoneIp} 2>/dev/null || true
      iptables -t nat -D POSTROUTING -s ${cfg.phoneIp} -d ${cfg.phoneIp} -j SNAT --to-source ${cfg.sidestoreIp} 2>/dev/null || true
    '';
  };
}
