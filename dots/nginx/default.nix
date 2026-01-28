{ ... }:

{
  services.nginx = {
    enable = true;
    group = "acme";
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "catvitalio@gmail.com";
  };
}
