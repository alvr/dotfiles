{ config, lib, ... }:
let
  cfg = config.dot.services.prowlarr;

  subdomain = "prowlarr";
  port = 9696;
in
{
  options.dot.services.prowlarr = {
    enable = lib.mkEnableOption "Enable Prowlarr service";
  };

  config = lib.mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
      settings.server.port = port;
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/".proxyWebsockets = true;
        }
      ];

      oauth2-proxy.hosts.${subdomain}.allowed_groups = [ "prowlarr_users" ];
    };

    dot.system.persistence.directories = [
      "/var/lib/private/prowlarr"
    ];

    systemd.services.prowlarr = {
      requires = [
        "nginx.service"
        "oauth2-proxy.service"
      ];
      after = [
        "nginx.service"
        "oauth2-proxy.service"
      ];
    };
  };
}
