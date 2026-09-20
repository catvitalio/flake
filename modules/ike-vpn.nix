{
  lib,
  config,
  pkgs,
  ...
}:

# IKEv2 (strongSwan) road-warrior VPN for clients on the OS-native stack
# (macOS/iOS built-in client, no extra app). Server auth: ACME cert for
# `domain`; client auth: own CA (public cert via `caCert`, private key stays
# agenix-encrypted in the secrets repo as ikeCaKey.age).
#
# Issuing a cert for a new device:
#   age -d -i ~/.ssh/id_ed25519 ikeCaKey.age > ca.key
#   openssl ecparam -name prime256v1 -genkey -noout -out dev.key
#   openssl req -new -key dev.key -subj "/CN=<dev>.vpn.catvitalio.com" -out dev.csr
#   printf "subjectAltName=DNS:<dev>.vpn.catvitalio.com\nextendedKeyUsage=clientAuth,serverAuth\nkeyUsage=digitalSignature" > ext.cnf
#   openssl x509 -req -in dev.csr -CA ike-ca.pem -CAkey ca.key -CAcreateserial -days 3650 -extfile ext.cnf -out dev.pem
#   openssl pkcs12 -export -inkey dev.key -in dev.pem -certfile ike-ca.pem -out dev.p12
# then wrap dev.p12 into a .mobileconfig (AuthenticationMethod=Certificate,
# RemoteAddress/RemoteIdentifier = `domain`) and shred ca.key.
let
  cfg = config.my.ikeVpn;
  iptables = "${pkgs.iptables}/bin/iptables";
  acmeDir = "/var/lib/acme/${cfg.domain}";
  # strongswan's config parser treats dots as section separators, so section
  # names derived from certificate identities must use the first label only.
  shortName = id: builtins.head (lib.splitString "." id);

  connBase = {
    version = 2;
    proposals = [
      "aes256gcm16-prfsha384-ecp384"
      "aes256-sha256-modp2048"
      "default"
    ];
    rekey_time = "24h";
    send_cert = "always";
    local.main = {
      auth = "pubkey";
      certs = [ "vpn-fullchain.pem" ];
      id = cfg.domain;
    };
    children.rw = {
      local_ts = [ "0.0.0.0/0" ];
      esp_proposals = [
        "aes256gcm16-ecp384"
        "aes256gcm16"
        "aes256-sha256"
      ];
      dpd_action = "clear";
    };
  };
in
{
  options.my.ikeVpn = {
    enable = lib.mkEnableOption "IKEv2 road-warrior VPN";
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Endpoint domain; also the ACME cert and server identity.";
    };
    caCert = lib.mkOption {
      type = lib.types.path;
      description = "Public certificate of the client CA.";
    };
    lanIp = lib.mkOption {
      type = lib.types.str;
      description = "This host's LAN address: pushed as DNS and used for the in-LAN endpoint override.";
    };
    wanInterface = lib.mkOption {
      type = lib.types.str;
      description = "Interface to masquerade pool traffic towards the LAN.";
    };
    pool = lib.mkOption {
      type = lib.types.str;
      description = "Full client subnet (firewall/NAT scope).";
    };
    sharedPoolRange = lib.mkOption {
      type = lib.types.str;
      description = "Address range handed to regular clients, excluding fixed ones.";
    };
    fixedClients = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Certificate identity -> fixed address (e.g. for the SideStore reflector).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Inside the LAN, resolve the VPN endpoint straight to this host so
    # clients don't depend on hairpin NAT through the router.
    services.dnsmasq.settings.address = [ "/${cfg.domain}/${cfg.lanIp}" ];

    security.acme.certs.${cfg.domain} = {
      dnsProvider = "timewebcloud";
      environmentFile = config.age.secrets.acmeEnv.path;
      reloadServices = [ "strongswan-swanctl.service" ];
    };

    # charon loads certs/keys from the /etc/swanctl directories
    systemd.tmpfiles.rules = [
      "L+ /etc/swanctl/x509/vpn-fullchain.pem - - - - ${acmeDir}/fullchain.pem"
      "L+ /etc/swanctl/private/vpn-key.pem - - - - ${acmeDir}/key.pem"
      "L+ /etc/swanctl/x509ca/vpn-ca.pem - - - - ${cfg.caCert}"
    ];

    systemd.services.strongswan-swanctl = {
      wants = [ "acme-finished-${cfg.domain}.target" ];
      after = [ "acme-finished-${cfg.domain}.target" ];
    };

    services.strongswan-swanctl = {
      enable = true;
      swanctl = {
        connections = {
          rw = connBase // {
            pools = [ "rw-pool" ];
            remote.main = {
              auth = "pubkey";
              cacerts = [ "vpn-ca.pem" ];
            };
          };
        }
        // lib.mapAttrs' (id: _: {
          name = "rw-${shortName id}";
          value = connBase // {
            pools = [ "pool-${shortName id}" ];
            remote.main = {
              auth = "pubkey";
              cacerts = [ "vpn-ca.pem" ];
              inherit id;
            };
          };
        }) cfg.fixedClients;

        pools = {
          rw-pool = {
            addrs = cfg.sharedPoolRange;
            # dnsmasq answers from the source address routing picks, which
            # for the IPsec pool is the LAN address — push that so replies
            # match the queried server ("reply from unexpected source").
            dns = [ cfg.lanIp ];
          };
        }
        // lib.mapAttrs' (id: addr: {
          name = "pool-${shortName id}";
          value = {
            addrs = "${addr}/32";
            dns = [ cfg.lanIp ];
          };
        }) cfg.fixedClients;
      };
    };

    networking.firewall.allowedUDPPorts = [
      500
      4500
    ];

    # IPsec has no interface, so trustedInterfaces can't apply: accept
    # decapsulated pool traffic by XFRM policy match, clamp MSS (the sing-box
    # tun is mtu 1280 downstream) and masquerade towards the LAN, which knows
    # no route back to the pool.
    networking.firewall.extraCommands = ''
      ${iptables} -A nixos-fw -m policy --dir in --pol ipsec -s ${cfg.pool} -j nixos-fw-accept
      ${iptables} -t mangle -A FORWARD -s ${cfg.pool} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
      ${iptables} -t mangle -A FORWARD -d ${cfg.pool} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
      ${iptables} -t nat -A POSTROUTING -s ${cfg.pool} -o ${cfg.wanInterface} -j MASQUERADE
    '';
    networking.firewall.extraStopCommands = ''
      ${iptables} -D nixos-fw -m policy --dir in --pol ipsec -s ${cfg.pool} -j nixos-fw-accept 2>/dev/null || true
      ${iptables} -t mangle -D FORWARD -s ${cfg.pool} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
      ${iptables} -t mangle -D FORWARD -d ${cfg.pool} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
      ${iptables} -t nat -D POSTROUTING -s ${cfg.pool} -o ${cfg.wanInterface} -j MASQUERADE 2>/dev/null || true
    '';
  };
}
