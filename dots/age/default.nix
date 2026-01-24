{
  pkgs,
  secrets,
  agenix-cli,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    age
    agenix-cli
  ];

  age = {
    identityPaths = [ "/home/v/.ssh/id_ed25519" ];
    secrets = {
      vPass = {
        file = "${secrets}/vPass.age";
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
  };
}
