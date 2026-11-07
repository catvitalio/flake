{ lib, pkgs, ... }:

let
  connector = "DP-2";

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

        mkdir -p /run/tv-cec
        exec 8>/run/tv-cec/adapter.lock
        ${pkgs.util-linux}/bin/flock -w 10 8

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

  # Keep one client alive for the whole exchange so the TV can query it back.
  # Address overrides and on/off exchanges must not share the adapter at once.
  cecSession =
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
      exec 8> $dir/adapter.lock
      ${pkgs.util-linux}/bin/flock -w 45 8
      fifo=$dir/${name}
      log=$dir/${name}.log
      rm -f $fifo
      mkfifo -m 0600 $fifo
      exec 9<> $fifo

      ${cecClient} -d 8 -t p -o steam < $fifo > $log 2>&1 &
      client=$!
      cleanup() {
        kill "$client" 2>/dev/null || true
        wait "$client" 2>/dev/null || true
        rm -f "$fifo"
      }
      trap cleanup EXIT
      trap 'exit 0' TERM INT

      ready=0
      for _ in $(seq 1 100); do
        kill -0 "$client" 2>/dev/null || { cat "$log" >&2; exit 1; }
        if grep -q "waiting for input" "$log"; then
          ready=1
          break
        fi
        sleep 0.1
      done
      [ "$ready" = 1 ] || { echo "CEC client did not become ready" >&2; exit 1; }

      send() {
        kill -0 "$client"
        printf '%s\n' "$1" >&9
      }

      ${commands}
    '';

  # The TV restores its previous input while waking, after an early Active
  # Source has already been sent. Wait for power-on, then reclaim the source
  # through libCEC so it also answers subsequent routing requests correctly.
  turnTvOn = cecSession "tv-on" ''
    send "on 0"
    powered_on=0
    for _ in $(seq 1 20); do
      line=$(wc -l < "$log")
      send "pow 0"
      sleep 1
      if tail -n +$((line + 1)) "$log" | grep -q '^power status: on$'; then
        powered_on=1
        break
      fi
    done
    [ "$powered_on" = 1 ] || { echo "TV did not report power-on" >&2; exit 1; }

    sleep 2
    for _ in $(seq 1 3); do
      send "as"
      sleep 2
    done
    send "self"
    sleep 1
    echo "requested active source on HDMI 1 after TV power-on"
  '';

  turnTvOff = cecSession "tv-off" ''
    send "standby 0"
    sleep 2
    echo "sent TV standby over CEC"
  '';

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
    after = sleepTargets ++ [
      "tv-cec-address.service"
      "tv-off.service"
    ];
    wants = [ "tv-cec-address.service" ];
    wantedBy = sleepTargets;
    serviceConfig = {
      Type = "oneshot";
      ExecCondition = tvControlAllowed;
      ExecStart = turnTvOn;
      TimeoutStartSec = "90s";
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
      TimeoutStartSec = "60s";
    };
  };
}
