{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    adw-gtk3
    morewaita-icon-theme
  ];

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        gtk-theme = "adw-gtk3";
        icon-theme = "MoreWaita";
      };
    }
  ];
}
