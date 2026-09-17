{ inputs, ... }:
{
  flake.modules.nixos.vaultwarden =
    { config, ... }:
    let
      subdomain = "vault";
      port = 8222;
    in
    {
      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        environmentFile = config.sops.secrets."vaultwarden/env".path;

        config = {
          DOMAIN = "https://${subdomain}.${config.dot.host.network.domain}";
          ROCKET_PORT = port;

          SSO_ENABLED = true;
          SSO_ONLY = true;
          SSO_AUTHORITY = "https://id.${config.dot.host.network.domain}";
          SSO_CLIENT_ID = "94c69e7b-c5f7-4c88-90a6-2fc0b8f06148";
          SSO_AUTH_ONLY_NOT_SESSION = true;
          SSO_SCOPES = "email profile groups offline_access";
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
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/vaultwarden.yaml";
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
