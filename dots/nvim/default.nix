{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  environment.systemPackages = with pkgs; [
    neovim-remote
    pkgs.ripgrep
    pkgs.gcc
    pkgs.lazygit
    pkgs.cmake
  ];
}
