{ ... }:

{
  services.nginx = {
    enable = true;
    clientMaxBodySize = "100m";
    group = "acme";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "catvitalio@gmail.com";
  };
}
