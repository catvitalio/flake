{ config, pkgs, ... }:

{
  users.users.v = {
    isNormalUser = true;
    description = "v";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
    hashedPasswordFile = config.age.secrets.vPass.path;
  };
}
