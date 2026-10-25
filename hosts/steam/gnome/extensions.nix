{ pkgs, ... }:

{
  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
  ];

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/shell".enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
      ];
    }
  ];
}
