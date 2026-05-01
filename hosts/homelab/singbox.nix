{ ... }:

{
  imports = [ ../../modules/singbox.nix ];

  my.singbox = {
    enable = true;
    networkInterface = "eno1";
  };
}
