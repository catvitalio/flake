{ lib, config, ... }:

# SideStore loopback reflector for a phone on the WireGuard tunnel. iOS forbids
# an app from connecting to the device's own RemotePairing service, so SideStore
# talks to a virtual device address instead; this NAT pair bounces those
# connections straight back to the phone through the tunnel, replacing StosVPN.
# The phone needs a fixed tunnel address, and its client config has to route the
# virtual address into the tunnel too.
let
  cfg = config.my.sidestoreReflector;
in
{
  options.my.sidestoreReflector = {
    enable = lib.mkEnableOption "SideStore loopback reflector for a phone on WireGuard";
    interface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Tunnel interface the phone arrives on.";
    };
    phoneIp = lib.mkOption {
      type = lib.types.str;
      description = "Fixed tunnel address of the phone.";
    };
    sidestoreIp = lib.mkOption {
      type = lib.types.str;
      default = "10.7.0.1";
      description = "Virtual device address SideStore connects to.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.extraCommands = ''
      iptables -t nat -A PREROUTING -i ${cfg.interface} -s ${cfg.phoneIp} -d ${cfg.sidestoreIp} -j DNAT --to-destination ${cfg.phoneIp}
      iptables -t nat -A POSTROUTING -s ${cfg.phoneIp} -d ${cfg.phoneIp} -j SNAT --to-source ${cfg.sidestoreIp}
    '';
    networking.firewall.extraStopCommands = ''
      iptables -t nat -D PREROUTING -i ${cfg.interface} -s ${cfg.phoneIp} -d ${cfg.sidestoreIp} -j DNAT --to-destination ${cfg.phoneIp} 2>/dev/null || true
      iptables -t nat -D POSTROUTING -s ${cfg.phoneIp} -d ${cfg.phoneIp} -j SNAT --to-source ${cfg.sidestoreIp} 2>/dev/null || true
    '';
  };
}
