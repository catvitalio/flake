{
  config,
  pkgs,
  ...
}:

let
  yamlFormat = import ../../lib/yaml-format.nix pkgs;
in
{
  services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  environment.etc."lact/config.yaml".source = yamlFormat.generate {
    version = 7;
    daemon = {
      log_level = "info";
      admin_group = "wheel";
      disable_clocks_cleanup = false;
    };
    apply_settings_timer = 5;
    gpus."1002:7550-1043:061A-0000:03:00.0" = {
      fan_control_enabled = false;
      power_cap = 260.0;
      performance_level = "auto";
      voltage_offset = -55;
    };
    current_profile = null;
    auto_switch_profiles = false;
  };

  systemd.services.lactd.restartTriggers = [
    config.environment.etc."lact/config.yaml".source
  ];
}
