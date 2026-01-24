{ config, ... }:

{
  services.restic.backups.important = {
    initialize = true;
    repository = "rclone:yandex-disk:/backup/restic";
    rcloneConfigFile = config.age.secrets.rcloneConf.path;
    paths = [
      "/var/lib/anytype"
      "/var/lib/vaultwarden"
    ];
    passwordFile = config.age.secrets.resticPass.path;
    timerConfig = {
      OnBootSec = "3m";
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
