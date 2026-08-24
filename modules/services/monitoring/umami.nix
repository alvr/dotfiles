{ inputs, ... }:
{
  flake.modules.nixos.umami =
    { config, ... }:
    let
      subdomain = "stats";
      port = 2468;
    in
    {
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
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/umami.yaml";
        mode = "0400";
        restartUnits = [ "umami.service" ];
      };

      systemd.services.umami = {
        requires = [ "nginx.service" ];
        after = [ "nginx.service" ];
      };
    };
}
