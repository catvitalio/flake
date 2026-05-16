{
  self,
  ...
}:

{
  imports = [ self.nixosModules.wrappedProton ];

  my.wrappedProton = {
    cachyos = {
      displayName = "CachyOS";
      enable = true;
      exports = {
        SteamDeck = "0";
        SteamGenericControllers = ""; # fix EA App
      };
    };

    cachyos-fsr4 = {
      displayName = "CachyOS FSR4";
      enable = true;
      exports = {
        SteamDeck = "0";
        SteamGenericControllers = "";
        PROTON_FSR4_UPGRADE = "1";
      };
    };

  };
}
