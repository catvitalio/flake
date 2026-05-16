{
  config,
  lib,
  pkgs,
  nix-cachyos-kernel,
  ...
}:

let
  cfg = config.my.cachyosKernel;
in
{
  options.my.cachyosKernel = {
    enable = lib.mkEnableOption "CachyOS kernel";

    package = lib.mkOption {
      type = lib.types.str;
      default = "linuxPackages-cachyos-latest";
      description = ''
        Attribute name from pkgs.cachyosKernels to use for boot.kernelPackages.
      '';
    };
  };

  config = lib.mkMerge [
    {
      nix.settings = {
        substituters = [ "https://attic.xuyh0120.win/lantian" ];
        trusted-public-keys = [
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        ];
      };
    }

    (lib.mkIf cfg.enable {
      nixpkgs.overlays = [ nix-cachyos-kernel.overlays.default ];
      boot.kernelPackages = pkgs.cachyosKernels.${cfg.package};
    })
  ];
}
