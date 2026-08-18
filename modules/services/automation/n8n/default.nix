{ inputs, ... }:
{
  flake.modules.nixos.n8n =
    { config, ... }:
    let
      subdomain = "auto";
      port = 5678;
    in
    {
      services.n8n = {
        enable = true;
        environment = {
          N8N_EDITOR_BASE_URL = "https://${subdomain}.${config.dot.host.network.domain}/";
          N8N_ENCRYPTION_KEY_FILE = config.sops.secrets."n8n/encryption-key".path;
          N8N_HOST = "${subdomain}.${config.dot.host.network.domain}";
          N8N_PORT = toString port;
          N8N_HIRING_BANNER_ENABLED = "false";
          N8N_RUNNERS_ENABLED = "true";

          N8N_PUBLIC_API_DISABLED = "true";
          N8N_PUBLIC_API_SWAGGERUI_DISABLED = "true";
        };
      };

      dot.services = {
        cloudflared.subdomains = [ subdomain ];
        postgresql.databases = [ "n8n" ];
        nginx.hosts = [
          {
            inherit subdomain port;
            config.locations."/".proxyWebsockets = true;
          }
        ];
      };

      dot.system.persistence.directories = [
        "/var/lib/private/n8n"
      ];

      sops.secrets."n8n/encryption-key" = {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/n8n.yaml";
        mode = "0400";
        restartUnits = [ "n8n.service" ];
      };
    };
}
