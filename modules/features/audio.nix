{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    let
      audioSplit = pkgs.writeShellScriptBin "audio-split-front-rear" ''
        set -e

        VIRTUAL=headset_front

        for _ in $(seq 1 30); do
          PHYSICAL=$(pactl list sinks short | awk '$2 ~ /\.analog-stereo$/ {print $2; exit}')
          [ -n "$PHYSICAL" ] && break
          sleep 1
        done

        [ -n "$PHYSICAL" ] || exit 1

        pactl list sinks short | grep -q " $VIRTUAL " || \
          pactl load-module module-remap-sink \
            sink_name="$VIRTUAL" \
            master="$PHYSICAL" \
            sink_properties=device.description=Headset \
            channels=2 \
            master_channel_map=front-left,front-right \
            channel_map=front-left,front-right \
            remix=no

        sync() {
          case "$(pactl get-default-sink)" in
            "$VIRTUAL") pactl set-sink-port "$PHYSICAL" analog-output-headphones ;;
            "$PHYSICAL") pactl set-sink-port "$PHYSICAL" analog-output-lineout ;;
          esac
        }

        sync
        pactl subscribe | grep --line-buffered "on sink" | while read -r _; do sync; done
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
        jack.enable = true;
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
          coreutils
          gawk
          gnugrep
          pulseaudio
        ];

        serviceConfig = {
          ExecStart = "${audioSplit}/bin/audio-split-front-rear";
          Restart = "on-failure";
        };
      };
    };
}
