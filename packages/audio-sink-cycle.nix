{
  writeShellApplication,
  coreutils,
  libnotify,
  pulseaudio,
}:
writeShellApplication {
  name = "audio-sink-cycle";
  runtimeInputs = [
    coreutils
    libnotify
    pulseaudio
  ];
  text = ''
    export LC_ALL=C

    direction=''${1:-next}

    mapfile -t sinks < <(pactl list short sinks | cut -f2 | sort -u)
    count=''${#sinks[@]}
    [ "$count" -gt 0 ] || exit 0

    current=$(pactl get-default-sink)
    index=-1
    for i in "''${!sinks[@]}"; do
      if [ "''${sinks[i]}" = "$current" ]; then index=$i; fi
    done

    if [ "$index" -lt 0 ]; then
      target=''${sinks[0]}
    else
      step=1
      [ "$direction" = prev ] && step=-1
      target=''${sinks[$(((index + step + count) % count))]}
    fi

    [ "$target" = "$current" ] && exit 0

    description=$(pactl list sinks | awk -v s="$target" '
      $1 == "Name:" { f = ($2 == s); next }
      f && $1 == "Description:" { sub(/^[ \t]*Description:[ \t]*/, ""); print; exit }
    ')

    pactl set-default-sink "$target"

    while read -r id; do
      pactl move-sink-input "$id" "$target"
    done < <(pactl list short sink-inputs | cut -f1)

    notify-send \
      --app-name=audio-sink-cycle \
      --icon=audio-speakers \
      --urgency=low \
      --expire-time=1500 \
      --hint=string:x-canonical-private-synchronous:audio-sink \
      "Audio output" "''${description:-$target}" || true
  '';
}
