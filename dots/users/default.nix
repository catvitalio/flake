{
  config,
  pkgs,
  ...
}:

let
  authorizedKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBf43Z9OMTqpOs2ncg0TUmEJmHN24HERiAirRSWInFpW catvitalio@gmail.com";
in
{
  users.users = {
    v = {
      isNormalUser = true;
      description = "v";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
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
    "v"
    "root"
  ];
}
