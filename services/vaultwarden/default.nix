{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.vaultwarden;

  subdomain = "vault";
  port = 8222;
in
{
  options.dot.services.vaultwarden = {
    enable = lib.mkEnableOption "Enable Vaultwarden service";
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      environmentFile = config.sops.secrets."vaultwarden/env".path;

      config = {
        DOMAIN = "https://${subdomain}.${consts.domain}";
        ROCKET_PORT = port;

        SSO_ENABLED = true;
        SSO_ONLY = true;
        SSO_AUTHORITY = "https://id.${consts.domain}";
        SSO_CLIENT_ID = "94c69e7b-c5f7-4c88-90a6-2fc0b8f06148";
        SSO_AUTH_ONLY_NOT_SESSION = true;
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "vaultwarden" ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations = {
            "= /notifications/anonymous-hub" = {
              proxyPass = "http://${subdomain}";
              proxyWebsockets = true;
            };
            "= /notifications/hub" = {
              proxyPass = "http://${subdomain}";
              proxyWebsockets = true;
            };
          };
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/vaultwarden";
        user = "vaultwarden";
        group = "vaultwarden";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."vaultwarden/env" = {
      sopsFile = ../../secrets/services/vaultwarden.yaml;
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
      restartUnits = [ "vaultwarden.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/vaultwarden 0700 vaultwarden vaultwarden -"
    ];
  };
}
