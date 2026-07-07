{ pkgs, ... }:
{
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "i915"
      "kvm-amd"
    ];
    kernelParams = [
      "amd_pstate=active"
    ];
    blacklistedKernelModules = [ "pcspkr" ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
      ];
    };
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    GST_VAAPI_ALL_DRIVERS = "1";
  };
}
