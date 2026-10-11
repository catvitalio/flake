{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = "v";
  authorizedKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBf43Z9OMTqpOs2ncg0TUmEJmHN24HERiAirRSWInFpW catvitalio@gmail.com";
in
{
  options.my.user = lib.mkOption {
    type = lib.types.str;
    description = "The interactive user this host is set up for.";
  };

  config = {
    my.user = user;

    users.users = {
      ${user} = {
        isNormalUser = true;
        description = user;
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "audio"
          "users"
          "input"
        ];
        shell = pkgs.fish;
        hashedPasswordFile = config.age.secrets.vPass.path;
        openssh.authorizedKeys.keys = [
          authorizedKey
        ];
      };
      root = {
        shell = pkgs.fish;
        openssh.authorizedKeys.keys = [
          authorizedKey
        ];
      };
    };

    programs.fish.enable = true;
    programs.starship = {
      enable = true;
      settings = {
        add_newline = true;
      };
    };

    nix.settings.trusted-users = [
      user
      "root"
    ];
  };
}
