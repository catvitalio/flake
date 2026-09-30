{ pkgs, ... }:

let
  rebootScript = pkgs.writeShellScript "reboot-to-windows" ''
    entry=$(${pkgs.efibootmgr}/bin/efibootmgr \
      | ${pkgs.gnused}/bin/sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\? .*Windows Boot Manager.*/\1/p' \
      | ${pkgs.coreutils}/bin/head -1)

    if [ -z "$entry" ]; then
      echo "reboot-to-windows: no Windows Boot Manager entry found"
      exit 1
    fi

    echo "reboot-to-windows: setting BootNext to $entry"
    ${pkgs.efibootmgr}/bin/efibootmgr --bootnext "$entry" >/dev/null
    ${pkgs.systemd}/bin/systemctl reboot
  '';

  launcher = pkgs.writeShellScriptBin "boot-windows" ''
    exec ${pkgs.systemd}/bin/systemctl start reboot-to-windows.service
  '';
in
{
  systemd.services.reboot-to-windows = {
    description = "Reboot into Windows once";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = rebootScript;
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == "v" &&
          action.lookup("verb") == "start" &&
          action.lookup("unit") == "reboot-to-windows.service") {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = [ launcher ];

  programs.steam.config = {
    enable = true;

    nonSteamApps."Windows" = {
      target = launcher;
      artwork = {
        icon = ../../assets/windows/icon.png;
        cover = ../../assets/windows/cover.png;
        header = ../../assets/windows/header.png;
        hero = ../../assets/windows/hero.png;
        logo = ../../assets/windows/logo.png;
      };
    };
  };
}
