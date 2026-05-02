{
  self,
  ...
}:

{
  imports = [ self.nixosModules.wrappedProton ];

  my.wrappedProton = {
    proton-cachyos = {
      displayName = "Proton CachyOS";
      enable = true;
      exports = {
        SteamDeck = "0";
        SteamGenericControllers = ""; # fix EA App
      };
    };

    proton-cachyos-fsr4 = {
      displayName = "Proton CachyOS FSR4";
      enable = true;
      exports = {
        SteamDeck = "0";
        SteamGenericControllers = "";
        PROTON_FSR4_UPGRADE = "1";
      };
    };
  };
}
