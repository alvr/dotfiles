{ inputs, ... }:
{
  flake.modules.nixos.wakapi =
    { config, lib, ... }:
    let
      subdomain = "waka";
      port = 4664;
    in
    {
      services.wakapi = {
        enable = true;
        environmentFiles = [ config.sops.secrets."wakapi/env".path ];

        settings = {
          app = {
            avatar_url_template = "https://gravatar.com/avatar/{email_hash}?s=200&d=robohash&r=x";
            import_enabled = false;
            leaderboard_require_auth = true;
          };

          db = {
            dialect = "postgres";
            host = "/run/postgresql";
            port = 5432;
            user = "wakapi";
            name = "wakapi";
          };

          security = {
            allow_signup = false;
            disable_frontpage = true;
            disable_local_auth = true;
            expose_metrics = true;
            insecure_cookies = false;
            invite_codes = false;
            trust_reverse_proxy_ips = "127.0.0.1,::1";

            oidc = [
              {
                name = "id-alvr";
                display_name = "id.alvr";
                client_id = "5f913537-8bf0-4810-8a90-6399e7f9a1c5";
                client_secret = "$WAKAPI_OIDC_PROVIDERS_0_CLIENT_SECRET";
                endpoint = "https://id.${config.dot.host.network.domain}";
              }
            ];
          };

          server = {
            inherit port;
            public_url = "https://${subdomain}.${config.dot.host.network.domain}";
          };
        };
      };

      dot.services = {
        cloudflared.subdomains = [ subdomain ];
        postgresql.databases = [ "wakapi" ];
        nginx.hosts = [
          {
            inherit subdomain port;
            config.locations."/api/metrics".return = 403;
          }
        ];
        prometheus.scrape.wakapi = lib.mkIf config.services.prometheus.enable {
          inherit port;
          bearer_token_file = config.sops.secrets."wakapi/metrics-bearer".path;
          metrics_path = "/api/metrics";
        };
      };

      sops.secrets = {
        "wakapi/env" = {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/wakapi.yaml";
          owner = "wakapi";
          group = "wakapi";
          mode = "0400";
          restartUnits = [ "wakapi.service" ];
        };

        "wakapi/metrics-bearer" = lib.mkIf config.services.prometheus.enable {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/wakapi.yaml";
          owner = "prometheus";
          group = "prometheus";
          mode = "0400";
          restartUnits = [ "prometheus.service" ];
        };
      };
    };
}
