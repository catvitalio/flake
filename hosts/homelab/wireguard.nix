{
  config,
  pkgs,
  secrets,
  ...
}:

let
  workInterface = "wg1";
  work = import "${secrets}/work.nix";
  iptables = "${pkgs.iptables}/bin/iptables";
in
{
  networking.wireguard.interfaces.${workInterface} = {
    ips = [ work.address ];
    privateKeyFile = config.age.secrets.wireguardWorkKey.path;
    peers = work.peers;
    postSetup = "${iptables} -t nat -A POSTROUTING -o ${workInterface} -j MASQUERADE";
    postShutdown = "${iptables} -t nat -D POSTROUTING -o ${workInterface} -j MASQUERADE 2>/dev/null || true";
  };

  networking.firewall.trustedInterfaces = [ workInterface ];
}
