{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    let
      audioSplit = pkgs.writeShellScriptBin "audio-split-front-rear" ''
        set -e

        export LC_ALL=C
        VIRTUAL=headset_front

        for _ in $(seq 1 30); do
          PHYSICAL=$(pactl list sinks short | awk '$2 ~ /\.analog-stereo$/ {print $2; exit}')
          [ -n "$PHYSICAL" ] && break
          sleep 1
        done

        [ -n "$PHYSICAL" ] || exit 1

        pactl list sinks short | awk -v v="$VIRTUAL" '$2 == v {f=1} END {exit !f}' || \
          pactl load-module module-remap-sink \
            sink_name="$VIRTUAL" \
            master="$PHYSICAL" \
            sink_properties=device.description=Headset \
            channels=2 \
            master_channel_map=front-left,front-right \
            channel_map=front-left,front-right \
            remix=no

        CARD=$(pactl list sinks | awk -v s="$PHYSICAL" '
          $1 == "Name:" && $2 == s { found = 1; next }
          found && $1 == "alsa.card" { gsub(/[^0-9]/, "", $3); print $3; exit }
        ')
        [ -n "$CARD" ] && amixer -c "$CARD" sset "Auto-Mute Mode" Disabled >/dev/null || true

        active_port() {
          pactl list sinks | awk -v s="$PHYSICAL" '
            $1 == "Name:" && $2 == s { found = 1; next }
            found && $1 == "Active" && $2 == "Port:" { print $3; exit }
          '
        }

        sync() {
          case "$(pactl get-default-sink)" in
            "$VIRTUAL") PORT=analog-output-headphones ;;
            "$PHYSICAL") PORT=analog-output-lineout ;;
            *) return ;;
          esac

          [ "$(active_port)" = "$PORT" ] || pactl set-sink-port "$PHYSICAL" "$PORT"
        }

        sync
        pactl subscribe | while read -r event; do
          case "$event" in
            *"on server"*|*"on sink "*) sync ;;
          esac
        done
      '';
    in
    {
      environment.systemPackages = with pkgs; [
        pavucontrol
        pulseaudio
      ];

      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };

      systemd.user.services.audio-split-front-rear = {
        description = "Separate front headphones and rear speakers";
        after = [
          "pipewire-pulse.service"
          "wireplumber.service"
        ];
        wantedBy = [ "default.target" ];

        path = with pkgs; [
          alsa-utils
          coreutils
          gawk
          pulseaudio
        ];

        serviceConfig = {
          ExecStart = "${audioSplit}/bin/audio-split-front-rear";
          Restart = "always";
          RestartSec = 2;
        };
      };
    };
}
