{ pkgs, ... }:

{
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    gnome-console
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-software
    gnome-text-editor
    gnome-tour
    gnome-weather
    simple-scan
    yelp
  ];

  environment.systemPackages = [ pkgs.ghostty ];

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/applications/terminal" = {
        exec = "ghostty";
        exec-arg = "-e";
      };
    }
  ];
}
