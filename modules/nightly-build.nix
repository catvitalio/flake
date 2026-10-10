{
  lib,
  config,
  pkgs,
  ...
}:

# Nightly NixOS pre-builds for remote machines, both ends of the flow.
#
# `builder` pulls the latest flake from the repo (flake.lock is bumped by GitHub
# Actions) and builds the target's configuration locally, keeping the result as
# a GC root under /var/lib/nightly-build/<name>/result. The target machine is
# NOT woken.
#
# `updater` runs on that target and picks the build up itself: it reads the
# result symlink over SSH and copies the closure from the build host's store.
# Both ends live here because they agree on one thing — the path convention
# derived from <name> — and that agreement is the whole protocol.
let
  cfg = config.my.nightlyBuild;

  resultLink = name: "/var/lib/nightly-build/${name}/result";

  builderOptions =
    name:
    {
      enable = lib.mkEnableOption "nightly builds of ${name} on this machine";

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

  updaterOptions = _name: {
    enable = lib.mkEnableOption "picking up nightly builds made for this machine";

    builderHost = lib.mkOption {
      type = lib.types.str;
      description = "Address of the machine that builds this configuration.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      description = "Session user allowed to start the update units via polkit.";
    };
    steamosButton = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Wire the SteamOS "Check for updates" button to these units by replacing
        Jovian's holo-update stub. Only meaningful on a Jovian host.
      '';
    };
  };

  hostType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        builder = lib.mkOption {
          type = lib.types.submodule { options = builderOptions name; };
          default = { };
          description = "Build ${name} on this machine on a schedule.";
        };
        updater = lib.mkOption {
          type = lib.types.submodule { options = updaterOptions name; };
          default = { };
          description = "Pick up builds of ${name} made elsewhere.";
        };
      };
    }
  );

  builders = lib.filterAttrs (_: host: host.builder.enable) cfg;
  updaters = lib.filterAttrs (_: host: host.updater.enable) cfg;

  buildScript =
    name: host:
    let
      dir = "/var/lib/nightly-build/${name}";
      checkout = "${dir}/flake";
      builder = host.builder;
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

      # Retry the fetch: a transient DNS/network hiccup at 5:00 used to kill
      # the whole night's build (2026-09-17..19 all failed on resolution).
      fetched=0
      for i in 1 2 3; do
        if [ -d ${checkout}/.git ]; then
          git -C ${checkout} fetch origin main && fetched=1 && break
        else
          mkdir -p ${checkout}
          git clone --branch main ${builder.repo} ${checkout} && fetched=1 && break
        fi
        echo "fetch attempt $i failed, retrying in 60s"
        sleep 60
      done
      [ "$fetched" = 1 ] || exit 1
      git -C ${checkout} reset --hard origin/main
      echo "flake at $(git -C ${checkout} rev-parse --short HEAD)"

      nix build \
        --out-link ${dir}/result \
        ${
          lib.optionalString (
            builder.substituters != [ ]
          ) "--option extra-substituters '${lib.concatStringsSep " " builder.substituters}'"
        } \
        ${
          lib.optionalString (
            builder.trustedPublicKeys != [ ]
          ) "--option extra-trusted-public-keys '${lib.concatStringsSep " " builder.trustedPublicKeys}'"
        } \
        "${checkout}#nixosConfigurations.${builder.configuration}.config.system.build.toplevel"
      echo "built $(readlink ${dir}/result)"

      # Overwriting the out-link dropped the previous build's GC root; collect
      # everything unrooted so old builds don't pile up on disk.
      nix store gc --quiet
    '';

  updaterUnits =
    name: host:
    let
      updater = host.updater;
      link = resultLink name;
      stateDir = "/var/lib/nixos-remote-update/${name}";
      unit = suffix: "nixos-remote-update-${name}${suffix}";
      ssh = "${pkgs.openssh}/bin/ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new root@${updater.builderHost}";

      checkScript = pkgs.writeShellScript "${unit ""}-check" ''
        set -eu
        mkdir -p ${stateDir}
        latest=$(${ssh} readlink ${link})
        case "$latest" in
          /nix/store/*) ;;
          *) echo "unexpected result path: $latest" >&2; exit 1 ;;
        esac
        echo "$latest" > ${stateDir}/latest
        echo "latest build on ${updater.builderHost}: $latest"
      '';

      # Always resolve the current build over SSH instead of trusting the file
      # from the last check: the nightly GC on the build host deletes old
      # builds, so a stale pointer would fail to download.
      fetchLatest = ''
        set -eu
        PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.nix
            pkgs.openssh
            pkgs.systemd
          ]
        }:$PATH
        latest=$(${ssh} readlink ${link})
        case "$latest" in
          /nix/store/*) ;;
          *) echo "unexpected result path: $latest" >&2; exit 1 ;;
        esac
        echo "fetching $latest from ${updater.builderHost}"
        NIX_SSHOPTS="-o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
          nix --extra-experimental-features 'nix-command' \
          copy --no-check-sigs --from ssh://root@${updater.builderHost} "$latest"
      '';

      applyScript = pkgs.writeShellScript "${unit ""}-apply" ''
        ${fetchLatest}
        nix-env -p /nix/var/nix/profiles/system --set "$latest"
        # Run switch in a transient unit: if the new generation changes this
        # very service, switch would otherwise restart it and kill itself
        # mid-activation (seen 2026-09-10 as "Failed with result 'signal'").
        systemd-run --collect --wait --quiet --unit=${unit "-switch"} \
          "$latest/bin/switch-to-configuration" switch
      '';
    in
    {
      inherit
        stateDir
        unit
        checkScript
        fetchLatest
        applyScript
        ;
      prefetchScript = pkgs.writeShellScript "${unit ""}-prefetch" fetchLatest;
    };

  # Replaces Jovian's holo-update stub inside the Steam FHS environment. Runs
  # as the session user; delegates to the root units above.
  #
  # steamos-update exit codes: 0 update applied, 1 error, 7 no update,
  # 8 reboot needed.
  steamosScript =
    name: host:
    let
      u = updaterUnits name host;
    in
    pkgs.writeShellScript "steamos-update" ''
      export PATH=/run/current-system/sw/bin:$PATH
      echo "steamos-update called with: $*" | systemd-cat -t nixos-updater

      # Steam passes extra flags (e.g. --supports-duplicate-detection), so look
      # for "check" anywhere in the arguments, not just in $1.
      # Steam only understands 0 (update available) / 7 (up to date) from a
      # check call — returning 8 here makes the UI show a generic update error
      # after every successfully applied update that changed the kernel.
      if case " $* " in *" check "*) true ;; *) false ;; esac then
        systemctl start ${u.unit "-check"}.service || exit 1
        latest=$(cat ${u.stateDir}/latest 2>/dev/null) || exit 1
        [ -n "$latest" ] || exit 1
        if [ "$latest" = "$(readlink /run/current-system)" ]; then
          exit 7
        fi
        exit 0
      fi

      # Only an explicit press of the Update button passes
      # --enable-duplicate-detection; Steam's background update loop calls the
      # same command with --supports-duplicate-detection alone and expects
      # SteamOS staging semantics — for those, just prefetch the closure so the
      # real Update is instant, but never switch on our own.
      if case " $* " in *" --enable-duplicate-detection "*) true ;; *) false ;; esac then
        systemctl start ${u.unit ""}.service || exit 1
        if [ "$(readlink /run/booted-system/kernel)" != "$(readlink /nix/var/nix/profiles/system/kernel)" ]; then
          exit 8
        fi
        exit 0
      fi

      systemctl start ${u.unit "-prefetch"}.service || exit 1
      exit 0
    '';
in
{
  options.my.nightlyBuild = lib.mkOption {
    default = { };
    type = lib.types.attrsOf hostType;
    description = "Machines pre-built on a nightly schedule, and the picking up of those builds.";
  };

  config = lib.mkMerge [
    {
      systemd.services = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "nightly-build-${name}" {
          description = "Nightly NixOS build for ${name}";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment.HOME = "/root";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = buildScript name host;
            TimeoutStartSec = "180min";
          };
        }
      ) builders;

      systemd.timers = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "nightly-build-${name}" {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = host.builder.onCalendar;
            Persistent = false;
          };
        }
      ) builders;
    }

    {
      systemd.services = lib.mkMerge (
        lib.mapAttrsToList (
          name: host:
          let
            u = updaterUnits name host;
          in
          {
            "${u.unit "-check"}" = {
              description = "Fetch the latest nightly build path for ${name}";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = u.checkScript;
              };
            };
            "${u.unit ""}" = {
              description = "Apply the latest nightly build for ${name}";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = u.applyScript;
                TimeoutStartSec = "60min";
              };
            };
            "${u.unit "-prefetch"}" = {
              description = "Prefetch the latest nightly build for ${name}";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = u.prefetchScript;
                TimeoutStartSec = "60min";
              };
            };
          }
        ) updaters
      );

      security.polkit.extraConfig = lib.concatStrings (
        lib.mapAttrsToList (
          name: host:
          let
            u = updaterUnits name host;
            allowed = map (s: ''action.lookup("unit") == "${u.unit s}.service"'') [
              "-check"
              ""
              "-prefetch"
            ];
          in
          ''
            polkit.addRule(function(action, subject) {
              if (action.id == "org.freedesktop.systemd1.manage-units" &&
                  subject.user == "${host.updater.user}" &&
                  action.lookup("verb") == "start" &&
                  (${lib.concatStringsSep " ||\n       " allowed})) {
                return polkit.Result.YES;
              }
            });
          ''
        ) updaters
      );

      nixpkgs.overlays = lib.mapAttrsToList (
        name: host:
        (final: prev: {
          jovian-stubs = prev.jovian-stubs.overrideAttrs (old: {
            buildCommand = old.buildCommand + ''
              install -D -m 755 ${steamosScript name host} $out/bin/holo-update
              install -D -m 755 ${steamosScript name host} $out/bin/steamos-polkit-helpers/steamos-update
            '';
          });
        })
      ) (lib.filterAttrs (_: host: host.updater.steamosButton) updaters);
    }
  ];
}
