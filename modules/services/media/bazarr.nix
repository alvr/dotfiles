{ inputs, ... }:
{
  flake.modules.nixos.bazarr =
    { config, lib, ... }:
    let
      subdomain = "bazarr";
      port = 6767;
    in
    {
      services = {
        bazarr = {
          enable = true;
          listenPort = port;
        };

        prometheus.exporters.exportarr-bazarr = lib.mkIf config.services.prometheus.enable {
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

            oidc.allowedGroups = [ "bazarr_users" ];
          }
        ];

        prometheus.scrape.bazarr = lib.mkIf config.services.prometheus.enable {
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

      sops.secrets."bazarr/api-key" = lib.mkIf config.services.prometheus.enable {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/bazarr.yaml";
        owner = "bazarr";
        group = "bazarr";
        mode = "0400";
        restartUnits = [ "prometheus-exportarr-bazarr-exporter.service" ];
      };

      systemd.services = {
        bazarr = {
          requires = [ "nginx.service" ];
          after = [ "nginx.service" ];
        };

        prometheus-exportarr-bazarr-exporter = lib.mkIf config.services.prometheus.enable {
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
