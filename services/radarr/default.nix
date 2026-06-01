{ config, lib, ... }:
let
  cfg = config.dot.services.radarr;

  subdomain = "radarr";
  port = 7878;
in
{
  options.dot.services.radarr = {
    enable = lib.mkEnableOption "Enable Radarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      radarr = {
        enable = true;
        dataDir = "/var/lib/radarr";
        settings.server.port = port;
      };

      prometheus.exporters.exportarr-radarr = lib.mkIf config.dot.services.prometheus.enable {
        enable = true;
        apiKeyFile = config.sops.secrets."radarr/api-key".path;
        port = port + 1;
        url = "http://localhost:${toString port}";
        inherit (config.services.radarr) user group;
      };
    };

    dot.services = {
      nginx.hosts = [
        {
          inherit subdomain port;
          internal = true;
          config.locations."/".proxyWebsockets = true;
        }
      ];
      oauth2-proxy.hosts.${subdomain}.allowed_groups = [ "radarr_users" ];
      prometheus.scrape.radarr = lib.mkIf config.dot.services.prometheus.enable {
        inherit (config.services.prometheus.exporters.exportarr-radarr) port;
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/radarr";
        user = "radarr";
        group = "radarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."radarr/api-key" = lib.mkIf config.dot.services.prometheus.enable {
      sopsFile = ../../secrets/services/radarr.yaml;
      owner = "radarr";
      group = "radarr";
      mode = "0400";
      restartUnits = [ "prometheus-exportarr-radarr-exporter.service" ];
    };

    systemd.services = {
      radarr = {
        requires = [
          "nginx.service"
          "oauth2-proxy.service"
        ];
        after = [
          "nginx.service"
          "oauth2-proxy.service"
        ];
      };

      prometheus-exportarr-radarr-exporter = lib.mkIf config.dot.services.prometheus.enable {
        requires = [
          "radarr.service"
          "prometheus.service"
        ];
        after = [
          "radarr.service"
          "prometheus.service"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/radarr 0700 radarr radarr -"
    ];

    users.groups.media = { };
    users.users.radarr.extraGroups = [ "media" ];
  };
}
