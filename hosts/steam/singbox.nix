{ self, ... }:

{
  imports = [ self.nixosModules.singbox ];

  my.singbox = {
    enable = true;
    mode = "tun";
    networkInterface = "enp11s0";
  };
}
