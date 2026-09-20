{
  lib,
  pkgs,
  ...
}:

# Wires the SteamOS "Check for updates" button to the nightly NixOS build made
# on homelab (see modules/nightly-build.nix). The Steam client calls
# steamos-update (Jovian's holo-update stub, replaced here via overlay) as the
# session user; the privileged work happens in root systemd units the user is
# allowed to start via a polkit rule.
#
# steamos-update exit codes: 0 update applied, 1 error, 7 no update, 8 reboot
# needed.
let
  buildHost = "192.168.1.2";
  resultLink = "/var/lib/nightly-build/steam/result";
  stateDir = "/var/lib/nixos-remote-update";
  ssh = "${pkgs.openssh}/bin/ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=accept-new root@${buildHost}";

  checkScript = pkgs.writeShellScript "nixos-remote-update-check" ''
    set -eu
    mkdir -p ${stateDir}
    latest=$(${ssh} readlink ${resultLink})
    case "$latest" in
      /nix/store/*) ;;
      *) echo "unexpected result path: $latest" >&2; exit 1 ;;
    esac
    echo "$latest" > ${stateDir}/latest
    echo "latest build on ${buildHost}: $latest"
  '';

  # Always resolve the current build over SSH instead of trusting the file
  # from the last check: the nightly GC on the build host deletes old builds,
  # so a stale pointer would fail to download.
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
    latest=$(${ssh} readlink ${resultLink})
    case "$latest" in
      /nix/store/*) ;;
      *) echo "unexpected result path: $latest" >&2; exit 1 ;;
    esac
    echo "fetching $latest from ${buildHost}"
    NIX_SSHOPTS="-o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
      nix --extra-experimental-features 'nix-command' \
      copy --no-check-sigs --from ssh://root@${buildHost} "$latest"
  '';

  # Background prefetch only: Steam's update loop calls the apply-style
  # command on its own (it expects SteamOS staging semantics), so this just
  # warms the store without touching the profile or switching.
  prefetchScript = pkgs.writeShellScript "nixos-remote-update-prefetch" fetchLatest;

  applyScript = pkgs.writeShellScript "nixos-remote-update-apply" ''
    ${fetchLatest}
    nix-env -p /nix/var/nix/profiles/system --set "$latest"
    # Run switch in a transient unit: if the new generation changes this very
    # service, switch would otherwise restart it and kill itself mid-activation
    # (seen 2026-09-10 as "Failed with result 'signal'").
    systemd-run --collect --wait --quiet --unit=nixos-remote-update-switch \
      "$latest/bin/switch-to-configuration" switch
  '';

  # Replaces Jovian's holo-update stub inside the Steam FHS environment.
  # Runs as the session user; delegates to the root units above.
  updateScript = pkgs.writeShellScript "steamos-update" ''
    export PATH=/run/current-system/sw/bin:$PATH
    echo "steamos-update called with: $*" | systemd-cat -t nixos-updater

    # Steam passes extra flags (e.g. --supports-duplicate-detection), so look
    # for "check" anywhere in the arguments, not just in $1.
    # Steam only understands 0 (update available) / 7 (up to date) from a
    # check call — returning 8 here makes the UI show a generic update error
    # after every successfully applied update that changed the kernel.
    if case " $* " in *" check "*) true ;; *) false ;; esac then
      systemctl start nixos-remote-update-check.service || exit 1
      latest=$(cat ${stateDir}/latest 2>/dev/null) || exit 1
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
      systemctl start nixos-remote-update.service || exit 1
      if [ "$(readlink /run/booted-system/kernel)" != "$(readlink /nix/var/nix/profiles/system/kernel)" ]; then
        exit 8
      fi
      exit 0
    fi

    systemctl start nixos-remote-update-prefetch.service || exit 1
    exit 0
  '';
in
{
  nixpkgs.overlays = [
    (final: prev: {
      jovian-stubs = prev.jovian-stubs.overrideAttrs (old: {
        buildCommand = old.buildCommand + ''
          install -D -m 755 ${updateScript} $out/bin/holo-update
          install -D -m 755 ${updateScript} $out/bin/steamos-polkit-helpers/steamos-update
        '';
      });
    })
  ];

  systemd.services.nixos-remote-update-check = {
    description = "Fetch the latest nightly build path from the build host";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = checkScript;
    };
  };

  systemd.services.nixos-remote-update = {
    description = "Apply the latest nightly build from the build host";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = applyScript;
      TimeoutStartSec = "60min";
    };
  };

  systemd.services.nixos-remote-update-prefetch = {
    description = "Prefetch the latest nightly build from the build host";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = prefetchScript;
      TimeoutStartSec = "60min";
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == "v" &&
          action.lookup("verb") == "start" &&
          (action.lookup("unit") == "nixos-remote-update-check.service" ||
           action.lookup("unit") == "nixos-remote-update-prefetch.service" ||
           action.lookup("unit") == "nixos-remote-update.service")) {
        return polkit.Result.YES;
      }
    });
  '';
}
