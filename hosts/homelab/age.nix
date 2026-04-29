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
    couchdbPass = {
      file = "${secrets}/couchdbPass.age";
      mode = "400";
      owner = "couchdb";
      group = "couchdb";
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
    wireguardKey = {
      file = "${secrets}/wireguardKey.age";
      mode = "400";
      owner = "root";
      group = "root";
    };
  };
}
