{ pkgs, ... }:
{
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.systemd.enable = false;
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-amd"
    ];
    kernelParams = [
      "amd_pstate=active"
    ];
    blacklistedKernelModules = [ "pcspkr" ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    graphics.enable = true;
    cpu.amd = {
      updateMicrocode = true;
      ryzen-smu.enable = true;
    };
  };

  powerManagement = {
    enable = true;
    powerUpCommands = "echo on > /sys/bus/pci/devices/0000:04:00.0/power/control";
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    GST_VAAPI_ALL_DRIVERS = "1";
  };
}
