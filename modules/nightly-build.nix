{
  lib,
  config,
  pkgs,
  ...
}:

# Nightly NixOS pre-builds for remote machines. Pulls the latest flake from the
# repo (flake.lock is bumped by GitHub Actions) and builds the target's
# configuration locally, keeping the result as a GC root under
# /var/lib/nightly-build/<name>/result. The target machine is NOT woken:
# it picks the build up itself later (e.g. via the SteamOS update button,
# see hosts/steam/updater.nix) by reading the result symlink over SSH and
# copying the closure from this host's store.
let
  cfg = config.my.nightlyBuild;

  hostType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        configuration = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "nixosConfigurations attribute to build.";
        };
        repo = lib.mkOption {
          type = lib.types.str;
          default = "git@github.com:catvitalio/flake.git";
          description = "Flake repository to pull before building.";
        };
        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "*-*-* 05:00:00 Asia/Krasnoyarsk";
          description = "systemd calendar expression for the build.";
        };
        substituters = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra binary caches the target configuration relies on.";
        };
        trustedPublicKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Public keys for the extra binary caches.";
        };
      };
    }
  );

  mkScript =
    name: host:
    let
      dir = "/var/lib/nightly-build/${name}";
      checkout = "${dir}/flake";
    in
    pkgs.writeShellScript "nightly-build-${name}" ''
      set -eu
      PATH=${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.git
          pkgs.openssh
          pkgs.nix
        ]
      }:$PATH

      if [ -d ${checkout}/.git ]; then
        git -C ${checkout} fetch origin main
        git -C ${checkout} reset --hard origin/main
      else
        mkdir -p ${checkout}
        git clone --branch main ${host.repo} ${checkout}
      fi
      echo "flake at $(git -C ${checkout} rev-parse --short HEAD)"

      nix build \
        --out-link ${dir}/result \
        ${lib.optionalString (host.substituters != [ ])
          "--option extra-substituters '${lib.concatStringsSep " " host.substituters}'"
        } \
        ${lib.optionalString (host.trustedPublicKeys != [ ])
          "--option extra-trusted-public-keys '${lib.concatStringsSep " " host.trustedPublicKeys}'"
        } \
        "${checkout}#nixosConfigurations.${host.configuration}.config.system.build.toplevel"
      echo "built $(readlink ${dir}/result)"

      # Overwriting the out-link dropped the previous build's GC root; collect
      # everything unrooted so old builds don't pile up on disk.
      nix store gc --quiet
    '';
in
{
  options.my.nightlyBuild = lib.mkOption {
    default = { };
    type = lib.types.attrsOf hostType;
    description = "Machine configurations to pre-build on a nightly schedule.";
  };

  config = {
    systemd.services = lib.mapAttrs' (
      name: host:
      lib.nameValuePair "nightly-build-${name}" {
        description = "Nightly NixOS build for ${name}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment.HOME = "/root";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = mkScript name host;
          TimeoutStartSec = "180min";
        };
      }
    ) cfg;

    systemd.timers = lib.mapAttrs' (
      name: host:
      lib.nameValuePair "nightly-build-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = host.onCalendar;
          Persistent = false;
        };
      }
    ) cfg;
  };
}
