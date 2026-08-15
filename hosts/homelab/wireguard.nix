{
  config,
  pkgs,
  secrets,
  ...
}:

let
  work = import "${secrets}/work.nix";
  iptables = "${pkgs.iptables}/bin/iptables";
  port = 51820;
in
{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/32" ];
    listenPort = port;
    privateKeyFile = config.age.secrets.wireguardKey.path;
    mtu = 1280;

    peers = [
      {
        publicKey = "b1/FwJYCTsUN5d/fV4fKHh9K44Am6u+4HbxKbT1ApgI=";
        allowedIPs = [ "10.100.0.10/32" ];
      }
      {
        publicKey = "+h6TarsS2HU3lf6ZG9gv60qChyO40tuW1rn+iqLIYSo=";
        allowedIPs = [ "10.100.0.11/32" ];
      }
      {
        publicKey = "sTvH3WJ8OHwBynHwdBmhuiaLT7bOniFFu0MowpOk2Vk=";
        allowedIPs = [ "10.100.0.12/32" ];
      }
      {
        publicKey = "aevcJc31KAERcLYbJJVIAosRppFTyKsBv0aH71wAIS8=";
        allowedIPs = [ "10.100.0.13/32" ];
      }
      {
        publicKey = "My6sL9VAgCY+kcw96KUxkIfqEH2e1C1hrHJsUrk3yhc=";
        allowedIPs = [ "10.100.0.14/32" ];
      }
    ];
  };

  networking.wireguard.interfaces.wg1 = {
    ips = [ work.address ];
    privateKeyFile = config.age.secrets.wireguardWorkKey.path;
    peers = work.peers;
    mtu = 1280;
    postSetup = "${iptables} -t nat -A POSTROUTING -o wg1 -j MASQUERADE";
    postShutdown = "${iptables} -t nat -D POSTROUTING -o wg1 -j MASQUERADE 2>/dev/null || true";
  };

  networking.firewall.allowedUDPPorts = [ port ];
  networking.firewall.trustedInterfaces = [
    "wg0"
    "wg1"
  ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
