{ ... }:

{
  services.openssh = {
    enable = true;
    openFirewall = true;
  };
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
