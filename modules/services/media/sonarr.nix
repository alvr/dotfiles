{ inputs, ... }:
{
  flake.modules.nixos.sonarr =
    { config, lib, ... }:
    let
      subdomain = "sonarr";
      port = 8989;
    in
    {
      services = {
        sonarr = {
          enable = true;
          dataDir = "/var/lib/sonarr";
          settings.server.port = port;
        };

        prometheus.exporters.exportarr-sonarr = lib.mkIf config.services.prometheus.enable {
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

            oidc.allowedGroups = [ "sonarr_users" ];
          }
        ];

        prometheus.scrape.sonarr = lib.mkIf config.services.prometheus.enable {
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

      sops.secrets."sonarr/api-key" = lib.mkIf config.services.prometheus.enable {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/sonarr.yaml";
        owner = "sonarr";
        group = "sonarr";
        mode = "0400";
        restartUnits = [ "prometheus-exportarr-sonarr-exporter.service" ];
      };

      systemd.services.prometheus-exportarr-sonarr-exporter = lib.mkIf config.services.prometheus.enable {
        requires = [
          "sonarr.service"
          "prometheus.service"
        ];
        after = [
          "sonarr.service"
          "prometheus.service"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/sonarr 0700 sonarr sonarr -"
      ];

      users.groups.media = { };
      users.users.sonarr.extraGroups = [ "media" ];
    };
}
