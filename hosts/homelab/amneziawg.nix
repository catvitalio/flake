{
  config,
  pkgs,
  ...
}:

let
  interface = "awg0";
  sock = "/run/amneziawg/${interface}.sock";
  port = 13231;
  serverIp = "10.100.0.1";
  subnet = "10.100.0.0/24";
  mobilePublicKeyHex = "b4cc1bd43fb3444b8cb703c85d787737c1b3ff53aaa1b6c4f374048031993d66";
  mobileIp = "10.100.0.10";
  ip = "${pkgs.iproute2}/bin/ip";
  ipt = "${pkgs.iptables}/bin/iptables";
  socat = "${pkgs.socat}/bin/socat";

  startScript = pkgs.writeShellScript "awg-start" ''
    # Wait for age secret
    i=0
    while [ ! -f "${config.age.secrets.amneziawgKey.path}" ] && [ "$i" -lt 10 ]; do
      sleep 1; i=$((i + 1))
    done
    [ -f "${config.age.secrets.amneziawgKey.path}" ] || { echo "secret not found"; exit 1; }

    # Remove stale interface if any
    ${ip} link delete ${interface} 2>/dev/null || true

    # Create interface (exits immediately when kernel module is available)
    ${pkgs.amneziawg-go}/bin/amneziawg-go ${interface}

    # Wait for UAPI socket (kernel module keeps it alive)
    i=0
    while [ ! -S "${sock}" ] && [ "$i" -lt 15 ]; do
      sleep 1; i=$((i + 1))
    done
    [ -S "${sock}" ] || { echo "awg socket not ready"; exit 1; }

    PRIV_HEX=$(base64 -d < "${config.age.secrets.amneziawgKey.path}" \
      | od -A n -t x1 -v | tr -d ' \n')

    printf 'set=1\nprivate_key=%s\nlisten_port=${toString port}\njc=4\njmin=40\njmax=70\ns1=0\ns2=0\nh1=1\nh2=2\nh3=3\nh4=4\nreplace_peers=true\npublic_key=${mobilePublicKeyHex}\nallowed_ip=${mobileIp}/32\n\n' \
      "$PRIV_HEX" | ${socat} - UNIX-CONNECT:${sock}

    ${ip} addr add ${serverIp}/24 dev ${interface}
    ${ip} link set ${interface} up
    ${ip} route replace ${mobileIp}/32 dev ${interface}

    ${ipt} -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    ${ipt} -t nat -A POSTROUTING -s ${subnet} ! -o ${interface} -j MASQUERADE
  '';

  stopScript = pkgs.writeShellScript "awg-stop" ''
    ${ipt} -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
    ${ipt} -t nat -D POSTROUTING -s ${subnet} ! -o ${interface} -j MASQUERADE 2>/dev/null || true
    ${ip} link delete ${interface} 2>/dev/null || true
  '';
in
{
  systemd.services.amneziawg = {
    description = "AmneziaWG";
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

  networking.firewall.allowedUDPPorts = [ port ];
  networking.firewall.trustedInterfaces = [ interface ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
