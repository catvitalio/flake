{
  config,
  pkgs,
  ...
}:

let
  interface = "awg0";
  sock = "/run/amneziawg/${interface}.sock";
  port = 13231;
  mobilePublicKeyHex = "b4cc1bd43fb3444b8cb703c85d787737c1b3ff53aaa1b6c4f374048031993d66";
  mobileIp = "10.100.0.10";
  ip = "${pkgs.iproute2}/bin/ip";
  socat = "${pkgs.socat}/bin/socat";

  configureScript = pkgs.writeShellScript "awg-configure" ''
    i=0
    while [ ! -S "${sock}" ] && [ "$i" -lt 15 ]; do
      sleep 1
      i=$((i + 1))
    done
    [ -S "${sock}" ] || { echo "awg socket not ready"; exit 1; }

    PRIV_HEX=$(base64 -d < "${config.age.secrets.amneziawgKey.path}" \
      | od -A n -t x1 -v | tr -d ' \n')

    printf 'set=1\nprivate_key=%s\nlisten_port=${toString port}\njc=4\njmin=40\njmax=70\ns1=0\ns2=0\nh1=1\nh2=2\nh3=3\nh4=4\nreplace_peers=true\npublic_key=${mobilePublicKeyHex}\nallowed_ip=${mobileIp}/32\n\n' \
      "$PRIV_HEX" | ${socat} - UNIX-CONNECT:${sock}

    ${ip} route replace ${mobileIp}/32 dev ${interface}
    ${ip} link set ${interface} up
  '';
in
{
  systemd.services.amneziawg = {
    description = "AmneziaWG";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "5s";
      RuntimeDirectory = "amneziawg";
      RuntimeDirectoryMode = "0700";
      ExecStartPre = "-${ip} link delete ${interface}";
      ExecStart = "${pkgs.amneziawg-go}/bin/amneziawg-go ${interface}";
      ExecStartPost = "${configureScript}";
      ExecStopPost = "-${ip} link delete ${interface}";
    };
  };

  networking.firewall.allowedUDPPorts = [ port ];
  networking.firewall.trustedInterfaces = [ interface ];
}
