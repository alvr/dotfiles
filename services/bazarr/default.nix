{ config, lib, ... }:
let
  cfg = config.dot.services.bazarr;

  subdomain = "bazarr";
  port = 6767;
in
{
  options.dot.services.bazarr = {
    enable = lib.mkEnableOption "Enable Bazarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      bazarr = {
        enable = true;
        listenPort = port;
      };

      prometheus.exporters.exportarr-bazarr = lib.mkIf config.dot.services.prometheus.enable {
        enable = true;
        apiKeyFile = config.sops.secrets."bazarr/api-key".path;
        port = port + 1;
        url = "http://localhost:${toString port}";
        inherit (config.services.bazarr) user group;
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
      oauth2-proxy.hosts.${subdomain}.allowed_groups = [ "bazarr_users" ];
      prometheus.scrape.bazarr = lib.mkIf config.dot.services.prometheus.enable {
        inherit (config.services.prometheus.exporters.exportarr-bazarr) port;
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/bazarr";
        user = "bazarr";
        group = "bazarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."bazarr/api-key" = lib.mkIf config.dot.services.prometheus.enable {
      sopsFile = ../../secrets/services/bazarr.yaml;
      owner = "bazarr";
      group = "bazarr";
      mode = "0400";
      restartUnits = [ "prometheus-exportarr-bazarr-exporter.service" ];
    };

    systemd.services = {
      bazarr = {
        requires = [
          "nginx.service"
          "oauth2-proxy.service"
        ];
        after = [
          "nginx.service"
          "oauth2-proxy.service"
        ];
      };

      prometheus-exportarr-bazarr-exporter = lib.mkIf config.dot.services.prometheus.enable {
        requires = [
          "bazarr.service"
          "prometheus.service"
        ];
        after = [
          "bazarr.service"
          "prometheus.service"
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/bazarr 0700 bazarr bazarr -"
    ];

    users.groups.media = { };
    users.users.bazarr.extraGroups = [ "media" ];
  };
}
