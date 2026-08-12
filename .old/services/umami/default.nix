{ config, lib, ... }:
let
  cfg = config.dot.services.umami;

  subdomain = "stats";
  port = 2468;
in
{
  options.dot.services.umami = {
    enable = lib.mkEnableOption "Enable Umami service";
  };

  config = lib.mkIf cfg.enable {
    services.umami = {
      enable = true;

      settings = {
        APP_SECRET_FILE = config.sops.secrets."umami/app-secret".path;
        CLIENT_IP_HEADER = "CF-Connecting-IP";
        COLLECT_API_ENDPOINT = "/api/kirby";
        DISABLE_TELEMETRY = true;
        PORT = port;
        SKIP_LOCATION_HEADERS = true;
        TRACKER_SCRIPT_NAME = [ "kirby.js" ];
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "umami" ];
      nginx.hosts = [
        { inherit subdomain port; }
      ];
    };

    sops.secrets."umami/app-secret" = {
      sopsFile = ../../secrets/services/umami.yaml;
      mode = "0400";
      restartUnits = [ "umami.service" ];
    };

    systemd.services.umami = {
      requires = [ "nginx.service" ];
      after = [ "nginx.service" ];
    };
  };
}
