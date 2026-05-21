{
  config,
  secrets,
  ...
}:

let
  homeInterface = "wg0";
  workInterface = "wg1";
  work = import "${secrets}/work.nix";
in
{
  networking.wireguard.interfaces = {
    ${homeInterface} = {
      ips = [ "10.100.0.2/24" ];
      privateKeyFile = config.age.secrets.wireguardKey.path;
      peers = [
        {
          publicKey = "mL2pYNjMdCjaW1CCFTVxeKUIbjlv3/Bg5vw0yfEO6H8=";
          allowedIPs = [ "10.100.0.0/24" ];
          endpoint = "192.168.1.1:51820";
          persistentKeepalive = 25;
        }
      ];
    };
    ${workInterface} = {
      ips = [ work.address ];
      privateKeyFile = config.age.secrets.wireguardWorkKey.path;
      peers = work.peers;
    };
  };

  networking.firewall.trustedInterfaces = [
    homeInterface
    workInterface
  ];

  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -o ${workInterface} -j MASQUERADE
    iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    ip6tables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
  '';

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
