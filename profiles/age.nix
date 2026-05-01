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
    identityPaths = [
      "/root/.ssh/id_ed25519"
    ];
    secrets = {
      vPass = {
        file = "${secrets}/vPass.age";
        mode = "400";
        owner = "root";
        group = "root";
      };
    };
  };
}
