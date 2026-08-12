{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.n8n;

  subdomain = "auto";
  port = 5678;
in
{
  options.dot.services.n8n = {
    enable = lib.mkEnableOption "Enable n8n service";
  };

  config = lib.mkIf cfg.enable {
    services.n8n = {
      enable = true;
      environment = {
        N8N_EDITOR_BASE_URL = "https://${subdomain}.${consts.domain}/";
        N8N_ENCRYPTION_KEY_FILE = config.sops.secrets."n8n/encryption-key".path;
        N8N_HOST = "${subdomain}.${consts.domain}";
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
      sopsFile = ../../secrets/services/n8n.yaml;
      mode = "0400";
      restartUnits = [ "n8n.service" ];
    };
  };
}
