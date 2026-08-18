{ inputs, ... }:
{
  flake.modules.nixos.home-assistant =
    {
      config,
      pkgs,
      ...
    }:
    let
      subdomain = "ha";
      port = 8123;
    in
    {
      services.home-assistant = {
        enable = true;

        config = {
          default_config = { };

          frontend = { };

          homeassistant = {
            name = "Hogar";
            latitude = "!secret latitude";
            longitude = "!secret longitude";
            elevation = "!secret elevation";
            temperature_unit = "C";
            time_zone = config.time.timeZone;
            unit_system = "metric";

            external_url = "https://${subdomain}.${config.dot.host.network.domain}";
          };

          http = {
            server_port = port;
            use_x_forwarded_for = true;
            trusted_proxies = [
              "::1"
              "127.0.0.1"
              config.dot.host.network.subnet
              config.dot.services.tailscale.subnet
            ];
          };
        };

        customComponents = with pkgs.home-assistant-custom-components; [
          auth_oidc
        ];

        customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
          card-mod
          material-you-utilities
        ];

        extraComponents = [
          # Core functionality
          "application_credentials"
          "bluetooth"
          "default_config"
          "ffmpeg"
          "met"
          "radio_browser"
          "shopping_list"

          # Smart devices
          "lg_thinq"
          "spotify"
          "mqtt"

          # Local media integration
          "jellyfin"
          "radarr"
          "sonarr"
          "webostv"

          # System monitoring
          "command_line"
          "systemmonitor"
          "uptime"

          # Network services
          "tailscale"

          # Voice and audio
          "esphome"

          # Mobile app support
          "mobile_app"
          "webhook"

          # Automation helpers
          "counter"
          "input_boolean"
          "input_button"
          "input_datetime"
          "input_number"
          "input_select"
          "input_text"
          "schedule"
          "timer"
        ];

        extraPackages =
          python3Packages: with python3Packages; [
            gtts # Google Text-to-speech

            aiogithubapi # Required for HACS

            isal # Fast zlib via isa-l (aiohttp_fast_zlib)
            zlib-ng # Modern zlib replacement (aiohttp_fast_zlib)

            aiowebostv # webostv (LG webOS TV)
            thinqconnect # lg_thinq (LG ThinQ)

            pydexcom # Dexcom Glucose Monitoring

            pyipp # IPP (Internet Printing Protocol) for printers
          ];

        themes = with pkgs.home-assistant-themes; [
          material-you-theme
        ];
      };

      dot.services.nginx.hosts = [
        {
          inherit subdomain port;
          internal = true;
          config.locations."= /api/websocket" = {
            proxyPass = "http://${subdomain}";
            proxyWebsockets = true;
          };
        }
      ];

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/hass";
          user = "hass";
          group = "hass";
          mode = "u=rwx,g=,o=";
        }
      ];

      hardware.bluetooth.enable = true;

      sops.secrets."home-assistant" = {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/home-assistant.yaml";
        owner = "hass";
        group = "hass";
        mode = "0400";
        restartUnits = [ "home-assistant.service" ];
        path = "/var/lib/hass/secrets.yaml";
      };

      systemd.services.home-assistant = {
        requires = [
          "nginx.service"
          "pocket-id.service"
        ];
        after = [
          "nginx.service"
          "pocket-id.service"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/hass 0700 hass hass -"
      ];

      users.users.hass.extraGroups = [ "bluetooth" ];
    };
}
