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

    dot = {
      services.cloudflared.subdomains = [ subdomain ];
      services.nginx.hosts = [
        { inherit subdomain port; }
      ];

      system.persistence.directories = [
        {
          directory = "/var/lib/radarr";
          user = "radarr";
          group = "radarr";
          mode = "u=rwx,g=,o=";
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/radarr 0700 radarr radarr -"
    ];

    users.groups.media = { };
    users.users.radarr.extraGroups = [ "media" ];
  };
}
