{
  config,
  lib,
  pkgs,
  ...
}:
let
  notifyScript = pkgs.writeShellScript "nixos-upgrade-notify" ''
    set -u

    status="$1"

    if [ "$status" = "success" ]; then
        previous_system="$(cat /run/nixos-upgrade-notify/previous-system 2>/dev/null || true)"
        current_system="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true)"

        if [ -z "$current_system" ] || [ "$current_system" = "$previous_system" ]; then
            exit 0
        fi

        title="NixOS upgraded on ${config.networking.hostName}"
        body="$(dix --color never "$previous_system" "$current_system" 2>/dev/null |
            sed -e '/^<<< /d' -e '/^>>> /d' -e 's/^\(\[..\] [^ ]\{1,\}\) \{1,\}/\1: /')"
    else
        title="NixOS upgrade failed on ${config.networking.hostName}"
        body="$(journalctl -u nixos-upgrade.service -n 40 --no-pager --output=cat 2>/dev/null || true)"
    fi

    [ -n "$body" ] || body="$title"

    send_chunk() {
        first="$1"
        chunk="$2"

        esc_body="$(printf '%s' "$chunk" | sed -e 's/\\/\\\\/g' -e 's/`/\\`/g')"
        if [ "$first" = "1" ]; then
            esc_title="$(printf '%s' "$title" | sed -e 's/\\/\\\\/g' -e 's/[][_*()~`>#+=|{}.!-]/\\&/g')"
            text="$(printf '*%s*\n```\n%s\n```' "$esc_title" "$esc_body")"
        else
            text="$(printf '```\n%s\n```' "$esc_body")"
        fi

        payload="$(jq -n \
            --arg chat "$TGRAM_CHANNEL" \
            --arg topic "$TGRAM_TOPIC" \
            --arg text "$text" \
            '{
              chat_id: ($chat | tonumber),
              message_thread_id: ($topic | tonumber),
              parse_mode: "MarkdownV2",
              disable_notification: true,
              text: $text
            }')"

        response="$(curl --silent --show-error --max-time 15 \
            --request POST \
            --header 'Content-Type: application/json' \
            --data "$payload" \
            "https://api.telegram.org/bot$TGRAM_TOKEN/sendMessage")"

        if ! printf '%s' "$response" | jq -e '.ok == true' >/dev/null 2>&1; then
            echo "telegram sendMessage failed: $response" >&2
            return 1
        fi
    }

    mapfile -t lines <<<"$body"
    first=1
    chunk=""
    for line in "''${lines[@]}"; do
        if [ -z "$chunk" ]; then
            chunk="$line"
        elif [ "$((''${#chunk} + ''${#line} + 1))" -gt 3500 ]; then
            send_chunk "$first" "$chunk" || true
            first=0
            chunk="$line"
        else
            chunk="$chunk"$'\n'"$line"
        fi
    done
    [ -n "$chunk" ] && { send_chunk "$first" "$chunk" || true; }
  '';
in
{
  config = lib.mkIf config.system.autoUpgrade.enable {
    sops.secrets."telegram-bot/env" = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    systemd.services.nixos-upgrade = {
      unitConfig = {
        OnSuccess = [ "nixos-upgrade-notify.service" ];
        OnFailure = [ "nixos-upgrade-notify.service" ];
      };
      path = [ pkgs.coreutils ];
      preStart = ''
        rm -rf /run/nixos-upgrade-notify
        mkdir -p /run/nixos-upgrade-notify
        readlink -f /nix/var/nix/profiles/system > /run/nixos-upgrade-notify/previous-system 2>/dev/null || true
      '';
    };

    systemd.services.nixos-upgrade-notify = {
      description = "Notify Telegram about NixOS upgrade status";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = with pkgs; [
        coreutils
        curl
        dix
        gnused
        jq
        systemd
      ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.secrets."telegram-bot/env".path;
      };
      script = ''
        result="''${MONITOR_SERVICE_RESULT:-}"
        [ -n "$result" ] || result="$(systemctl show -p Result --value nixos-upgrade.service)"
        ${notifyScript} $result || true
      '';
    };
  };
}
