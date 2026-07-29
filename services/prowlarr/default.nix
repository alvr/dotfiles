{ config, lib, ... }:
let
  cfg = config.dot.services.prowlarr;

  subdomain = "prowlarr";
  port = 9696;
in
{
  options.dot.services.prowlarr = {
    enable = lib.mkEnableOption "Enable Prowlarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      prowlarr = {
        enable = true;
        settings.server.port = port;
      };

      prometheus.exporters.exportarr-prowlarr = lib.mkIf config.dot.services.prometheus.enable {
        enable = true;
        port = port + 1;
        apiKeyFile = config.sops.secrets."prowlarr/api-key".path;
        url = "http://localhost:${toString port}";
      };
    };

    dot.services = {
      nginx.hosts = [
        {
          inherit subdomain port;
          internal = true;
          config.locations."/".proxyWebsockets = true;

          oidc.allowedGroups = [ "prowlarr_users" ];
        }
      ];

      prometheus.scrape.prowlarr = lib.mkIf config.dot.services.prometheus.enable {
        inherit (config.services.prometheus.exporters.exportarr-prowlarr) port;
      };
    };

    dot.system.persistence.directories = [
      "/var/lib/private/prowlarr"
    ];

    sops.secrets."prowlarr/api-key" = lib.mkIf config.dot.services.prometheus.enable {
      sopsFile = ../../secrets/services/prowlarr.yaml;
      mode = "0400";
      restartUnits = [ "prometheus-exportarr-prowlarr-exporter.service" ];
    };

    systemd.services = {
      prowlarr = {
        requires = [ "nginx.service" ];
        after = [ "nginx.service" ];
      };

      prometheus-exportarr-prowlarr-exporter = lib.mkIf config.dot.services.prometheus.enable {
        requires = [
          "prowlarr.service"
          "prometheus.service"
        ];
        after = [
          "prowlarr.service"
          "prometheus.service"
        ];
      };
    };
  };
}
