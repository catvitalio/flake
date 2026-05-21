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
      postSetup = "${iptables} -t nat -A POSTROUTING -o wg1 -j MASQUERADE";
      postShutdown = "${iptables} -t nat -D POSTROUTING -o wg1 -j MASQUERADE 2>/dev/null || true";
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
