{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.amneziawg-server;
  ip = "${pkgs.iproute2}/bin/ip";
  ipt = "${pkgs.iptables}/bin/iptables";
  socat = "${pkgs.socat}/bin/socat";
  sock = "/run/amneziawg/${cfg.interface}.sock";

  peerBlock = peer: lib.concatStringsSep "\\n" [
    "public_key=${peer.publicKey}"
    "allowed_ip=${peer.allowedIp}/32"
  ];

  startScript = pkgs.writeShellScript "awg-start" ''
    # Wait for private key file
    i=0
    while [ ! -f "${cfg.privateKeyFile}" ] && [ "$i" -lt 15 ]; do
      sleep 1; i=$((i + 1))
    done
    [ -f "${cfg.privateKeyFile}" ] || { echo "awg: private key not found"; exit 1; }

    # Remove stale interface
    ${ip} link delete ${cfg.interface} 2>/dev/null || true

    # Create interface (exits immediately when kernel module is available)
    ${pkgs.amneziawg-go}/bin/amneziawg-go ${cfg.interface}

    # Wait for UAPI socket
    i=0
    while [ ! -S "${sock}" ] && [ "$i" -lt 15 ]; do
      sleep 1; i=$((i + 1))
    done
    [ -S "${sock}" ] || { echo "awg: socket not ready"; exit 1; }

    PRIV_HEX=$(base64 -d < "${cfg.privateKeyFile}" | od -A n -t x1 -v | tr -d ' \n')

    printf 'set=1\nprivate_key=%s\nlisten_port=${toString cfg.port}\njc=${toString cfg.jc}\njmin=${toString cfg.jmin}\njmax=${toString cfg.jmax}\ns1=${toString cfg.s1}\ns2=${toString cfg.s2}\nh1=${toString cfg.h1}\nh2=${toString cfg.h2}\nh3=${toString cfg.h3}\nh4=${toString cfg.h4}\nreplace_peers=true\n${lib.concatMapStringsSep "\\n" peerBlock cfg.peers}\n\n' \
      "$PRIV_HEX" | ${socat} - UNIX-CONNECT:${sock}

    ${ip} addr add ${cfg.serverIp} dev ${cfg.interface}
    ${ip} link set ${cfg.interface} up

    ${lib.concatMapStringsSep "\n" (peer: ''
      ${ip} route replace ${peer.allowedIp}/32 dev ${cfg.interface}
    '') cfg.peers}

    ${ipt} -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    ${ipt} -t nat -A POSTROUTING -s ${cfg.subnet} ! -o ${cfg.interface} -j MASQUERADE
  '';

  stopScript = pkgs.writeShellScript "awg-stop" ''
    ${ipt} -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
    ${ipt} -t nat -D POSTROUTING -s ${cfg.subnet} ! -o ${cfg.interface} -j MASQUERADE 2>/dev/null || true
    ${ip} link delete ${cfg.interface} 2>/dev/null || true
  '';
in
{
  options.services.amneziawg-server = {
    enable = lib.mkEnableOption "AmneziaWG server";

    interface = lib.mkOption {
      type = lib.types.str;
      default = "awg0";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 51820;
    };

    serverIp = lib.mkOption {
      type = lib.types.str;
      example = "10.100.0.1/24";
      description = "Server IP with prefix length on the AWG interface.";
    };

    subnet = lib.mkOption {
      type = lib.types.str;
      example = "10.100.0.0/24";
      description = "VPN subnet for NAT masquerade.";
    };

    privateKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing the base64-encoded private key.";
    };

    peers = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          publicKey = lib.mkOption {
            type = lib.types.str;
            description = "Peer public key in hex format.";
          };
          allowedIp = lib.mkOption {
            type = lib.types.str;
            description = "Peer's VPN IP (without prefix).";
          };
        };
      });
      default = [];
    };

    # AmneziaWG obfuscation parameters
    jc   = lib.mkOption { type = lib.types.int; default = 4; };
    jmin = lib.mkOption { type = lib.types.int; default = 40; };
    jmax = lib.mkOption { type = lib.types.int; default = 70; };
    s1   = lib.mkOption { type = lib.types.int; default = 0; };
    s2   = lib.mkOption { type = lib.types.int; default = 0; };
    h1   = lib.mkOption { type = lib.types.int; default = 1; };
    h2   = lib.mkOption { type = lib.types.int; default = 2; };
    h3   = lib.mkOption { type = lib.types.int; default = 3; };
    h4   = lib.mkOption { type = lib.types.int; default = 4; };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.amneziawg-server = {
      description = "AmneziaWG server (${cfg.interface})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "amneziawg";
        RuntimeDirectoryMode = "0700";
        ExecStart = startScript;
        ExecStop = stopScript;
      };
    };

    networking.firewall.allowedUDPPorts = [ cfg.port ];
    networking.firewall.trustedInterfaces = [ cfg.interface ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
