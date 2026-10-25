{ inputs, ... }:
{
  flake.modules.nixos.miniflux =
    { config, lib, ... }:
    let
      subdomain = "rss";
      port = 9564;
    in
    {
      services.miniflux = {
        enable = true;
        adminCredentialsFile = config.sops.secrets."miniflux/env".path;
        createDatabaseLocally = true;
        config = {
          BASE_URL = "https://${subdomain}.${config.dot.host.network.domain}";
          LISTEN_ADDR = "localhost:${toString port}";
        };
      };

      dot.services = {
        cloudflared.subdomains = [ subdomain ];
        postgresql.databases = [ "miniflux" ];
        nginx.hosts = [
          {
            inherit subdomain port;
            config.locations."/metrics".return = 403;
          }
        ];
        prometheus.scrape.miniflux = lib.mkIf config.services.prometheus.enable {
          inherit port;
          basic_auth = {
            username = "prometheus";
            password_file = config.sops.secrets."miniflux/metrics-password".path;
          };
        };
      };

      sops.secrets = {
        "miniflux/env" = {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/miniflux.yaml";
          owner = "miniflux";
          group = "miniflux";
          mode = "0400";
          restartUnits = [ "miniflux.service" ];
        };

        "miniflux/metrics-password" = lib.mkIf config.services.prometheus.enable {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/miniflux.yaml";
          owner = "prometheus";
          group = "prometheus";
          mode = "0400";
          restartUnits = [ "prometheus.service" ];
        };
      };

      systemd.services.miniflux.serviceConfig.SupplementaryGroups = [ "miniflux" ];

      users.users.miniflux = {
        group = "miniflux";
        isSystemUser = true;
      };

      users.groups.miniflux = { };
    };
}
