{
  config,
  pkgs,
  ...
}:

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
    initrd.kernelModules = [ ];
    initrd.luks.devices."luks-823d4c73-dc5b-4e34-a515-53917072aa8d".device =
      "/dev/disk/by-uuid/823d4c73-dc5b-4e34-a515-53917072aa8d";
    kernelModules = [
      "i915"
      "kvm-amd"
      "amd-pstate"
    ];
    blacklistedKernelModules = [
      "snd_hda_intel"
      "snd_hda_codec_hdmi"
      "snd_hda_codec_realtek"
      "r8169"

      "bluetooth"
      "btusb"
      "btrtl"
      "btbcm"
      "btintel"

      "pcspkr"
    ];
    kernelParams = [
      "amd_pstate=guided"

      "pcie.aspm=force"
      "consoleblank=60"
      "acpi_enforce_resources=lax"
      "nvme_core.default_ps_max_latency_us=50000"

      "i915.enable_guc=3"
      "i915.enable_dc=2"
    ];
    extraModulePackages = [ config.boot.kernelPackages.r8125 ];
    extraModprobeConfig = ''
      options r8125 aspm=0
    '';
  };

  hardware = {
    enableRedistributableFirmware = true;
    alsa.enablePersistence = false;
    bluetooth.enable = false;

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
    cpuFreqGovernor = "schedutil";
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    INTEL_MEDIA_RUNTIME_DEFAULT_PROFILE = "low-power";
    GST_VAAPI_ALL_DRIVERS = "1";
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/813e5b78-afd1-49d6-9efb-e4a2c972fbb4";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/F296-5969";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
}
