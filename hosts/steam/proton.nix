{
  self,
  ...
}:

{
  imports = [ self.nixosModules.wrappedProton ];

  my.wrappedProton = {
    displayName = "Proton CachyOS";
    name = "proton-cachyos";
    enable = true;
    exports = {
      SteamDeck = "0"; # turn off steamdeck mode
      SteamGenericControllers = ""; # cut unneccessary long env var (ea app fix)
      PROTON_FSR4_UPGRADE = "1";
    };
  };
}
