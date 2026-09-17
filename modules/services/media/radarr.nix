{ inputs, ... }:
{
  flake.modules.nixos.radarr =
    { config, lib, ... }:
    let
      subdomain = "radarr";
      port = 7878;
    in
    {
      services = {
        radarr = {
          enable = true;
          dataDir = "/var/lib/radarr";
          settings.server.port = port;
        };

        prometheus.exporters.exportarr-radarr = lib.mkIf config.services.prometheus.enable {
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

            oidc.allowedGroups = [ "radarr_users" ];
          }
        ];

        prometheus.scrape.radarr = lib.mkIf config.services.prometheus.enable {
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

      sops.secrets."radarr/api-key" = lib.mkIf config.services.prometheus.enable {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/radarr.yaml";
        owner = "radarr";
        group = "radarr";
        mode = "0400";
        restartUnits = [ "prometheus-exportarr-radarr-exporter.service" ];
      };

      systemd.services.prometheus-exportarr-radarr-exporter = lib.mkIf config.services.prometheus.enable {
        requires = [
          "radarr.service"
          "prometheus.service"
        ];
        after = [
          "radarr.service"
          "prometheus.service"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/radarr 0700 radarr radarr -"
      ];

      users.groups.media = { };
      users.users.radarr.extraGroups = [ "media" ];
    };
}
