{
  config,
  ...
}:

{
  services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  environment.etc."lact/config.yaml".text = ''
    version: 7
    daemon:
      log_level: info
      admin_group: wheel
      disable_clocks_cleanup: false
    apply_settings_timer: 5
    gpus:
      # Fan curve stays stock/auto (zero-RPM idle): the card itself is quiet,
      # case fans driven by fan2go (fans.nix) do the extra cooling instead.
      "1002:7550-1043:061A-0000:03:00.0":
        fan_control_enabled: false
        fan_control_settings:
          mode: curve
          static_speed: 0.5
          temperature_key: edge
          interval_ms: 500
          curve:
            40: 0.3
            50: 0.35
            60: 0.5
            70: 0.75
            80: 1.0
          spindown_delay_ms: 5000
          change_threshold: 2
        power_cap: 260.0
        performance_level: auto
        voltage_offset: -55
    current_profile: null
    auto_switch_profiles: false
  '';

  systemd.services.lactd.restartTriggers = [
    config.environment.etc."lact/config.yaml".source
  ];
}
