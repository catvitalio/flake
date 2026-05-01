{
  self,
  ...
}:

{
  imports = [ self.nixosModules.singbox ];

  my.singbox = {
    enable = true;
    mode = "socks";
    networkInterface = "eno1";
  };
}
