{ lib, pkgs, ... }:

let
  connector = "DP-2";

  # Physical address of the TV port that carries the picture (HDMI 1).
  pictureAddress = "10:00";

  cecClient = lib.getExe' pkgs.libcec "cec-client";
  cecCtl = lib.getExe' pkgs.v4l-utils "cec-ctl";
  loginctl = "${pkgs.systemd}/bin/loginctl";

  # The kernel takes our CEC address from the connector's EDID, so we are a
  # device on the port the adapter sits in, and cec-ctl refuses to change it.
  # This TV only obeys a device that claims rights over its own port, so patch
  # the EDID's source physical address to the port that carries the picture.
  claimPictureAddress = pkgs.writeShellScript "tv-cec-address" ''
        PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.python3
          ]
        }

        dir=""
        for _ in $(seq 1 40); do
          for candidate in /sys/kernel/debug/dri/*/${connector}; do
            [ -d "$candidate" ] && dir=$candidate && break 2
          done
          sleep 0.25
        done
        [ -n "$dir" ] || { echo "no debugfs entry for ${connector}"; exit 1; }

        if ${cecCtl} -d /dev/cec0 2>/dev/null | grep -qE "Physical Address +: 1\.0\.0\.0"; then
          echo "already claiming the picture port"
          exit 0
        fi

        python3 -c '
    import pathlib, sys

    connector = pathlib.Path(sys.argv[1])
    edid = bytearray(pathlib.Path(sys.argv[2]).read_bytes())
    marker = edid.find(bytes([0x03, 0x0C, 0x00]))
    if marker < 0:
        sys.exit("no HDMI vendor block in the EDID")

    edid[marker + 3] = 0x10
    edid[marker + 4] = 0x00
    block = (marker // 128) * 128
    edid[block + 127] = (256 - (sum(edid[block:block + 127]) & 0xFF)) & 0xFF

    (connector / "edid_override").write_bytes(bytes(edid))
    (connector / "trigger_hotplug").write_text("1")
    ' "$dir" /sys/class/drm/card1-${connector}/edid

        for _ in $(seq 1 40); do
          ${cecCtl} -d /dev/cec0 2>/dev/null | grep -qE "Physical Address +: 1\.0\.0\.0" && break
          sleep 0.25
        done
        ${cecCtl} -d /dev/cec0 2>/dev/null | grep -i "Physical Address" | tr -s ' '
  '';

  # Every command goes out from a fresh client: the TV queries the sender back,
  # and a client that has already exited counts as absent, so the command is
  # dropped.
  cecCommands =
    name: commands:
    pkgs.writeShellScript name ''
      PATH=${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.gnugrep
        ]
      }
      dir=/run/tv-cec
      mkdir -p $dir
      fifo=$dir/${name}
      log=$dir/${name}.log
      rm -f $fifo
      mkfifo -m 0600 $fifo
      exec 9<> $fifo

      ${cecClient} -d 8 -t p -o steam < $fifo > $log 2>&1 &
      client=$!
      trap 'kill $client 2>/dev/null' EXIT

      for _ in $(seq 1 100); do
        grep -q "waiting for input" $log 2>/dev/null && break
        sleep 0.1
      done

      ${lib.concatMapStringsSep "\n      " (command: ''
        printf '%s\n' "${command}" > $fifo
        sleep 0.8
      '') commands}

      sleep 1
      echo "sent over cec: ${lib.concatStringsSep " then " commands}"
    '';

  # One touch play: turn the TV on and announce ourselves as the active source
  # on the picture port; the TV answers with Set Stream Path to that address.
  turnTvOn = cecCommands "tv-on" [
    "tx 40:04"
    "tx 4f:82:${pictureAddress}"
  ];

  turnTvOff = cecCommands "tv-off" [ "standby 0" ];

  tvControlAllowed = pkgs.writeShellScript "tv-control-allowed" ''
    session=$(${loginctl} show-seat seat0 -p ActiveSession --value 2>/dev/null)
    [ -n "$session" ] || exit 0
    case "$(${loginctl} show-session "$session" -p Desktop --value 2>/dev/null)" in
      [Gg][Nn][Oo][Mm][Ee]*) ;;
      *) exit 0 ;;
    esac

    for status in /sys/class/drm/card*-*/status; do
      name=''${status%/status}
      name=''${name##*/}
      case "$name" in
        *HDMI-A-1 | *${connector}) continue ;;
      esac
      [ "$(cat "$status" 2>/dev/null)" = connected ] && exit 1
    done
    exit 0
  '';

  sleepTargets = [
    "suspend.target"
    "hibernate.target"
    "hybrid-sleep.target"
  ];
in
{
  systemd.services.tv-cec-address = {
    description = "Make our CEC device claim the port that carries the picture";
    wantedBy = [ "multi-user.target" ] ++ sleepTargets;
    after = sleepTargets;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = claimPictureAddress;
      TimeoutStartSec = "30s";
    };
  };

  systemd.services.tv-on = {
    description = "Turn the TV on and select the picture input over CEC";
    after = sleepTargets ++ [ "tv-cec-address.service" ];
    wants = [ "tv-cec-address.service" ];
    wantedBy = sleepTargets;
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = tvControlAllowed;
      ExecStart = turnTvOn;
      TimeoutStartSec = "60s";
    };
  };

  systemd.services.tv-off = {
    description = "Put the TV into standby before suspending";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = tvControlAllowed;
      ExecStart = turnTvOff;
      TimeoutStartSec = "30s";
    };
  };
}
