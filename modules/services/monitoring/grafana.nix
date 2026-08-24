{ inputs, ... }:
{
  flake.modules.nixos.grafana =
    { config, lib, ... }:
    let
      subdomain = "metrics";
      port = 31313;
    in
    {
      services.grafana = {
        enable = true;
        settings = {
          auth.disable_login_form = true;
          "auth.basic".enabled = false;

          "auth.generic_oauth" = {
            enabled = true;
            client_id = "$__file{${config.sops.secrets."grafana/oauth2/client-id".path}}";
            client_secret = "$__file{${config.sops.secrets."grafana/oauth2/client-secret".path}}";
            scopes = "openid email profile groups";
            auth_url = "https://id.${config.dot.host.network.domain}/authorize";
            api_url = "https://id.${config.dot.host.network.domain}/api/oidc/userinfo";
            token_url = "https://id.${config.dot.host.network.domain}/api/oidc/token";
            role_attribute_path = "contains(groups[*], 'grafana_admins') && 'Admin' || contains(groups[*], 'grafana_editors') && 'Editor' || 'Viewer'";
          };

          database = {
            host = "/run/postgresql";
            user = "grafana";
            name = "grafana";
            type = "postgres";
          };

          security.secret_key = "$__file{${config.sops.secrets."grafana/secret-key".path}}";

          server = {
            http_port = port;
            root_url = "https://${subdomain}.${config.dot.host.network.domain}/";
          };
        };

        provision = {
          enable = true;
          datasources.settings.datasources = lib.optionals config.services.prometheus.enable [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:${toString config.services.prometheus.port}";
            }
          ];
        };
      };

      dot.services = {
        nginx.hosts = [
          {
            inherit subdomain port;
            internal = true;
            config.locations."/api/live/" = {
              proxyPass = "http://${subdomain}";
              proxyWebsockets = true;
            };
          }
        ];
        postgresql.databases = [ "grafana" ];
      };

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/grafana";
          user = "grafana";
          group = "grafana";
          mode = "u=rwx,g=,o=";
        }
      ];

      sops.secrets =
        let
          grafana-secret = {
            sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/grafana.yaml";
            owner = "grafana";
            group = "grafana";
            mode = "0400";
            restartUnits = [ "grafana.service" ];
          };
        in
        {
          "grafana/secret-key" = grafana-secret;
          "grafana/oauth2/client-id" = grafana-secret;
          "grafana/oauth2/client-secret" = grafana-secret;
        };

      systemd.services.grafana = {
        requires = [
          "postgresql.service"
        ]
        ++ lib.optionals config.services.prometheus.enable [ "prometheus.service" ];
        after = [
          "postgresql.service"
        ]
        ++ lib.optionals config.services.prometheus.enable [ "prometheus.service" ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/grafana 0700 grafana grafana -"
      ];
    };
}
