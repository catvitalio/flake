{ pkgs, ... }:

{
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", KERNEL=="usb3", ATTR{power/wakeup}="enabled"
  '';
}
