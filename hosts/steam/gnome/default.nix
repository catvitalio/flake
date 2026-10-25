{ ... }:

{
  imports = [
    ./app-grid.nix
    ./apps.nix
    ./extensions.nix
    ./theme.nix
  ];

  services.desktopManager.gnome.enable = true;
}
