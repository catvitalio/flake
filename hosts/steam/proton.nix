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

    cachyos-forza = {
      displayName = "CachyOS Forza";
      enable = true;
      exports = {
        SteamDeck = "0";
        VKD3D_CONFIG = "enable_experimental_features,descriptor_heap";
        PROTON_VKD3D_HEAP = "1";
      };
    };

  };
}
