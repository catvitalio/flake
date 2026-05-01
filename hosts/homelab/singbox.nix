{ self, ... }:

{
  imports = [ self.nixosModules.singbox ];

  my.singbox = {
    enable = true;
    networkInterface = "eno1";
  };
}
