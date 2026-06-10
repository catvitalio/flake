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
        RADV_EXPERIMENTAL = "heap";
        MESA_SHADER_CACHE_MAX_SIZE = "10G";
        radv_wait_for_vm_map_updates = "true";
      };
    };

  };
}
