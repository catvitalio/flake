{ config, lib, pkgs, secrets, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 3;
  };

  environment.systemPackages = [ pkgs.sbctl ];

  age.secrets.sbctlBundle = {
    file = "${secrets}/sbctlBundle.age";
  };

  system.activationScripts.sbctl-restore = {
    text = ''
      if [ ! -f /var/lib/sbctl/GUID ]; then
        mkdir -p /var/lib/sbctl
        ${pkgs.gnutar}/bin/tar -xzf ${config.age.secrets.sbctlBundle.path} -C /var/lib/sbctl
      fi
    '';
    deps = [ "agenix" ];
  };
}
