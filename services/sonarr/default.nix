{ config, lib, ... }:
let
  cfg = config.dot.services.sonarr;

  subdomain = "sonarr";
  port = 8989;
in
{
  options.dot.services.sonarr = {
    enable = lib.mkEnableOption "Enable Sonarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      sonarr = {
        enable = true;
        dataDir = "/var/lib/sonarr";
        settings.server.port = port;
      };

      prometheus.exporters.exportarr-sonarr = lib.mkIf config.dot.services.prometheus.enable {
        enable = true;
        apiKeyFile = config.sops.secrets."sonarr/api-key".path;
        port = port + 1;
        url = "http://localhost:${toString port}";
        inherit (config.services.sonarr) user group;
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
      oauth2-proxy.hosts.${subdomain}.allowed_groups = [ "sonarr_users" ];
      prometheus.scrape.sonarr = lib.mkIf config.dot.services.prometheus.enable {
        inherit (config.services.prometheus.exporters.exportarr-sonarr) port;
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/sonarr";
        user = "sonarr";
        group = "sonarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."sonarr/api-key" = lib.mkIf config.dot.services.prometheus.enable {
      sopsFile = ../../secrets/services/sonarr.yaml;
      owner = "sonarr";
      group = "sonarr";
      mode = "0400";
      restartUnits = [ "prometheus-exportarr-sonarr-exporter.service" ];
    };

    systemd.services = {
      sonarr = {
        requires = [
          "nginx.service"
          "oauth2-proxy.service"
        ];
        after = [
          "nginx.service"
          "oauth2-proxy.service"
        ];
      };

      prometheus-exportarr-sonarr-exporter = lib.mkIf config.dot.services.prometheus.enable {
        requires = [
          "sonarr.service"
          "prometheus.service"
        ];
        after = [
          "sonarr.service"
          "prometheus.service"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/sonarr 0700 sonarr sonarr -"
    ];

    users.groups.media = { };
    users.users.sonarr.extraGroups = [ "media" ];
  };
}
