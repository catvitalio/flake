{
  config,
  pkgs,
  secrets,
  ...
}:

let
  homeInterface = "wg0";
  workInterface = "wg1";
  work = import "${secrets}/work.nix";
  iptables = "${pkgs.iptables}/bin/iptables";
  ip6tables = "${pkgs.iptables}/bin/ip6tables";
in
{
  networking.wireguard.interfaces = {
    ${homeInterface} = {
      ips = [ "10.100.0.2/24" "fd00:100::2/64" ];
      mtu = 1410;
      privateKeyFile = config.age.secrets.wireguardKey.path;
      peers = [
        {
          publicKey = "mL2pYNjMdCjaW1CCFTVxeKUIbjlv3/Bg5vw0yfEO6H8=";
          allowedIPs = [ "10.100.0.0/24" "fd00:100::/64" ];
          endpoint = "192.168.1.1:51820";
          persistentKeepalive = 25;
        }
      ];
      postSetup = ''
        ${iptables} -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        ${ip6tables} -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
      '';
      postShutdown = ''
        ${iptables} -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
        ${ip6tables} -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
      '';
    };
    ${workInterface} = {
      ips = [ work.address ];
      mtu = 1410;
      privateKeyFile = config.age.secrets.wireguardWorkKey.path;
      peers = work.peers;
      postSetup = "${iptables} -t nat -A POSTROUTING -o ${workInterface} -j MASQUERADE";
      postShutdown = "${iptables} -t nat -D POSTROUTING -o ${workInterface} -j MASQUERADE 2>/dev/null || true";
    };
  };

  networking.firewall.trustedInterfaces = [
    homeInterface
    workInterface
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
