{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  environment.systemPackages = with pkgs; [
    neovim-remote
    ripgrep
    gcc
    lazygit
    cmake
  ];
}
