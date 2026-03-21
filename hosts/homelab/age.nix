{ secrets, ... }:

{
  age.secrets = {
    nextcloudPass = {
      file = "${secrets}/nextcloudPass.age";
      mode = "400";
      owner = "nextcloud";
      group = "nextcloud";
    };
    acmeEnv = {
      file = "${secrets}/acmeEnv.age";
      mode = "400";
      owner = "acme";
      group = "acme";
    };
    resticPass = {
      file = "${secrets}/resticPass.age";
      mode = "400";
      owner = "root";
      group = "root";
    };
    rcloneConf = {
      file = "${secrets}/rcloneConf.age";
      mode = "400";
      owner = "root";
      group = "root";
    };
  };
}
