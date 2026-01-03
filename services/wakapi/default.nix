{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.wakapi;

  subdomain = "waka";
  port = 4664;
in
{
  options.dot.services.wakapi = {
    enable = lib.mkEnableOption "Enable Wakapi service";
  };

  config = lib.mkIf cfg.enable {
    services.wakapi = {
      enable = true;
      passwordSaltFile = config.sops.secrets."wakapi/salt-password".path;
      smtpPasswordFile = config.sops.secrets."wakapi/smtp-password".path;

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
          disable_frontend = true;
          expose_metrics = false;
          insecure_cookies = false;
          invite_codes = false;
          trust_reverse_proxy_ips = "127.0.0.1,::1";

          oidc = [
            {
              name = "id-alvr";
              display_name = "id.alvr";
              client_id = "5f913537-8bf0-4810-8a90-6399e7f9a1c5";
              client_secret = "$WAKAPI_OIDC_PROVIDERS_0_CLIENT_SECRET";
              endpoint = "https://id.alvr.dev";
            }
          ];
        };

        server = {
          inherit port;
          public_url = "https://${subdomain}.${consts.domain}";
        };
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "wakapi" ];
      nginx.hosts = [
        { inherit subdomain port; }
      ];
    };

    sops.secrets = {
      "wakapi/oidc-secret" = {
        sopsFile = ../../secrets/services/wakapi.yaml;
        owner = "wakapi";
        group = "wakapi";
        mode = "0400";
        restartUnits = [ "wakapi.service" ];
      };

      "wakapi/salt-password" = {
        sopsFile = ../../secrets/services/wakapi.yaml;
        owner = "wakapi";
        group = "wakapi";
        mode = "0400";
        restartUnits = [ "wakapi.service" ];
      };

      "wakapi/smtp-password" = {
        sopsFile = ../../secrets/services/wakapi.yaml;
        owner = "wakapi";
        group = "wakapi";
        mode = "0400";
        restartUnits = [ "wakapi.service" ];
      };
    };

    sops.templates."wakapi/oidc-secret" = {
      content = ''
        WAKAPI_OIDC_PROVIDERS_0_CLIENT_SECRET=${config.sops.placeholder."wakapi/oidc-secret"}
      '';
      owner = "wakapi";
      group = "wakapi";
      mode = "0400";
    };

    systemd.services.wakapi.serviceConfig.EnvironmentFile = [
      config.sops.templates."wakapi/oidc-secret".path
    ];
  };
}
