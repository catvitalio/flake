{ self, ... }:

{
  imports = [ self.nixosModules.singbox ];

  my.singbox = {
    enable = true;
    networkInterface = "enp11s0";
  };
}
