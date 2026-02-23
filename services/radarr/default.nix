{ config, lib, ... }:
let
  cfg = config.dot.services.radarr;

  subdomain = "radarr";
  port = 7878;
in
{
  options.dot.services.radarr = {
    enable = lib.mkEnableOption "Enable Radarr service";
  };

  config = lib.mkIf cfg.enable {
    services.radarr = {
      enable = true;
      dataDir = "/var/lib/radarr";
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

      oauth2-proxy.hosts.${subdomain}.allowed_groups = [ "radarr_users" ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/radarr";
        user = "radarr";
        group = "radarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.services.radarr = {
      requires = [
        "nginx.service"
        "oauth2-proxy.service"
      ];
      after = [
        "nginx.service"
        "oauth2-proxy.service"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/radarr 0700 radarr radarr -"
    ];

    users.groups.media = { };
    users.users.radarr.extraGroups = [ "media" ];
  };
}
