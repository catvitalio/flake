{
  config,
  pkgs,
  secrets,
  ...
}:

let
  work = import "${secrets}/work.nix";
  iptables = "${pkgs.iptables}/bin/iptables";
in
{
  environment.systemPackages = with pkgs; [ amneziawg-tools ];

  networking.wireguard.interfaces.wg1 = {
    ips = [ work.address ];
    privateKeyFile = config.age.secrets.wireguardWorkKey.path;
    peers = work.peers;
    postSetup = "${iptables} -t nat -A POSTROUTING -o wg1 -j MASQUERADE";
    postShutdown = "${iptables} -t nat -D POSTROUTING -o wg1 -j MASQUERADE 2>/dev/null || true";
  };

  networking.wireguard.interfaces.awg0 = {
    ips = [ "10.100.0.1/24" ];
    listenPort = 47891;
    privateKeyFile = config.age.secrets.wireguardKey.path;
    mtu = 1280;

    postSetup = ''
      ${iptables} -t nat -A POSTROUTING -s 10.100.0.0/24 ! -o awg0 -j MASQUERADE
    '';
    postShutdown = ''
      ${iptables} -t nat -D POSTROUTING -s 10.100.0.0/24 ! -o awg0 -j MASQUERADE 2>/dev/null || true
    '';

    peers = [
      {
        publicKey = "b1/FwJYCTsUN5d/fV4fKHh9K44Am6u+4HbxKbT1ApgI=";
        allowedIPs = [ "10.100.0.10/32" ];
      }
      {
        publicKey = "+h6TarsS2HU3lf6ZG9gv60qChyO40tuW1rn+iqLIYSo=";
        allowedIPs = [ "10.100.0.11/32" ];
      }
    ];
  };

  networking.firewall.allowedUDPPorts = [ 47891 ];
  networking.firewall.trustedInterfaces = [ "wg1" "awg0" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
