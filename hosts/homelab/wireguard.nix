{
  config,
  lib,
  pkgs,
  secrets,
  devices,
  ...
}:

let
  clients = removeAttrs devices [ "homelab" ];
  work = import "${secrets}/work.nix";
  iptables = "${pkgs.iptables}/bin/iptables";
  port = 51820;
in
{
  networking.wireguard.interfaces.wg0 = {
    ips = [ "${devices.homelab.ip}/32" ];
    listenPort = port;
    privateKeyFile = config.age.secrets.wireguardKey.path;
    mtu = 1420;

    peers = lib.mapAttrsToList (_: device: {
      inherit (device) publicKey;
      allowedIPs = [ "${device.ip}/32" ];
    }) clients;
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
