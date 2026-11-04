{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.wireguardClient;
  interfaceUnit = "wireguard-${cfg.interface}";
  controller = pkgs.writeShellApplication {
    name = "wireguard-client";
    runtimeInputs = with pkgs; [
      iproute2
      bind.dnsutils
      openresolv
      gnugrep
    ];
    text = builtins.readFile ./wireguard-client.sh;
  };
in
{
  options.my.wireguardClient = {
    enable = lib.mkEnableOption "an IPv4 full-tunnel WireGuard client";
    interface = lib.mkOption {
      type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9_.-]{0,14}";
      default = "wg0";
      description = "WireGuard interface owned by this client.";
    };
    address = lib.mkOption {
      type = lib.types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+";
      example = "10.100.0.12/32";
      description = "IPv4 tunnel address with its prefix length.";
    };
    privateKeyFile = lib.mkOption {
      type = lib.types.str;
      description = "Runtime path to the WireGuard private key.";
    };
    dns = lib.mkOption {
      type = lib.types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+";
      example = "10.100.0.1";
      description = "IPv4 DNS server reached through the tunnel.";
    };
    mtu = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1420;
      description = "WireGuard interface MTU.";
    };
    peer = {
      publicKey = lib.mkOption {
        type = lib.types.str;
        description = "Server's WireGuard public key.";
      };
      endpoint = lib.mkOption {
        type = lib.types.str;
        example = "192.168.1.2:51820";
        description = "Server address or hostname and UDP port.";
      };
      persistentKeepalive = lib.mkOption {
        type = lib.types.ints.between 0 65535;
        default = 25;
        description = "Keepalive interval in seconds; zero disables keepalives.";
      };
    };
    failover.enable = lib.mkEnableOption ''
      direct internet access and network DNS when tunnel DNS stops responding.
      Two successful DNS probes restore the VPN. This checks tunnel and DNS
      availability, not the server's internet forwarding
    '';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.resolvconf.enable;
        message = "my.wireguardClient requires networking.resolvconf.enable for scoped VPN DNS.";
      }
    ];

    networking.wireguard.interfaces.${cfg.interface} = {
      ips = [ cfg.address ];
      inherit (cfg) privateKeyFile mtu;
      fwMark = "51820";
      allowedIPsAsRoutes = false;
      postSetup = ''
        ${pkgs.iproute2}/bin/ip -4 route replace default dev ${lib.escapeShellArg cfg.interface} table 51820
      '';
      peers = [ (cfg.peer // { allowedIPs = [ "0.0.0.0/0" ]; }) ];
    };

    systemd.services.wireguard-client = {
      description = "WireGuard client routing and DNS";
      wantedBy = [ "${interfaceUnit}.service" ];
      after = [
        "${interfaceUnit}.service"
        "${interfaceUnit}.target"
      ];
      bindsTo = [ "${interfaceUnit}.service" ];
      partOf = [ "${interfaceUnit}.service" ];
      environment = {
        WG_ADDRESS = lib.head (lib.splitString "/" cfg.address);
        WG_DNS = cfg.dns;
        WG_DNS_KEY = "${cfg.interface}.wireguard-client";
      };
      serviceConfig = {
        Type = if cfg.failover.enable then "exec" else "oneshot";
        RemainAfterExit = !cfg.failover.enable;
        ExecStart = "${controller}/bin/wireguard-client${
          lib.optionalString (!cfg.failover.enable) " start"
        }";
        ExecStopPost = "${controller}/bin/wireguard-client stop";
        Restart = if cfg.failover.enable then "always" else "on-failure";
        RestartSec = "5s";
        TimeoutStopSec = "30s";
      };
    };
  };
}
