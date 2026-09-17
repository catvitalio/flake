{ ... }:

let
  phone = "10.100.0.11";
  reflector = "10.7.0.1";
in
{
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -i wg0 -s ${phone} -d ${reflector} -j DNAT --to-destination ${phone}
    iptables -t nat -A POSTROUTING -o wg0 -s ${phone} -d ${phone} -j SNAT --to-source ${reflector}
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -i wg0 -s ${phone} -d ${reflector} -j DNAT --to-destination ${phone} 2>/dev/null || true
    iptables -t nat -D POSTROUTING -o wg0 -s ${phone} -d ${phone} -j SNAT --to-source ${reflector} 2>/dev/null || true
  '';
}
