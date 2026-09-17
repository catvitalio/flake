{ pkgs, ... }:

# Case fans on the Sapphire NITRO+ B850M (nct6799) are driven by the
# motherboard's CPU-based auto mode and never react to GPU load:
#   channel 1 — bottom fans next to the GPU  -> GPU edge temperature
#   channel 2 — top/rear exhaust             -> max(GPU, CPU)
#   channel 7 — AIO pump, left on firmware control (radiator fans are
#               handled by the cooler's own USB controller)
let
  fan2goConfig = (pkgs.formats.yaml { }).generate "fan2go.yaml" {
    dbPath = "/var/lib/fan2go/fan2go.db";
    fans = [
      {
        id = "bottom";
        hwmon = {
          platform = "nct6799-isa-0a40";
          index = 1;
        };
        neverStop = true;
        curve = "gpu_curve";
      }
      {
        id = "exhaust";
        hwmon = {
          platform = "nct6799-isa-0a40";
          index = 2;
        };
        neverStop = true;
        curve = "exhaust_curve";
      }
    ];
    sensors = [
      {
        id = "gpu";
        hwmon = {
          platform = "amdgpu-pci-0300";
          index = 1;
        };
      }
      {
        id = "cpu";
        hwmon = {
          platform = "k10temp-pci-00c3";
          index = 1;
        };
      }
    ];
    curves = [
      {
        id = "gpu_curve";
        linear = {
          sensor = "gpu";
          steps = [
            { "40" = 45; }
            { "55" = 60; }
            { "70" = 90; }
            { "85" = 160; }
          ];
        };
      }
      {
        id = "cpu_curve";
        linear = {
          sensor = "cpu";
          steps = [
            { "45" = 60; }
            { "65" = 120; }
            { "85" = 255; }
          ];
        };
      }
      {
        id = "exhaust_curve";
        function = {
          type = "maximum";
          curves = [
            "gpu_curve"
            "cpu_curve"
          ];
        };
      }
    ];
  };
in
{
  boot.kernelModules = [ "nct6775" ];

  systemd.services.fan2go = {
    description = "Case fan control driven by GPU/CPU temperature";
    after = [ "lactd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.fan2go}/bin/fan2go -c ${fan2goConfig} --no-style";
      StateDirectory = "fan2go";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
