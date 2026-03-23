{ pkgs, ... }:

{
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.configurationLimit = 3;
    loader.timeout = 0;
    initrd = {
      verbose = false;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };
    consoleLogLevel = 3;
    kernelModules = [
      "kvm-amd"
      "amdgpu"
    ];
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=false"
      "usbcore.autosuspend=-1"
    ];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-zen4;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
