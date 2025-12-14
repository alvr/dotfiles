{ config, lib, ... }:
let
  cfg = config.dot.services.sonarr;

  subdomain = "sonarr";
  port = 8989;
in
{
  options.dot.services.sonarr = {
    enable = lib.mkEnableOption "Enable Sonarr service";
  };

  config = lib.mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      dataDir = "/var/lib/sonarr";
      settings.server.port = port;
    };

    dot = {
      services.cloudflared.subdomains = [ subdomain ];
      services.nginx.hosts = [
        { inherit subdomain port; }
      ];

      system.persistence.directories = [
        {
          directory = "/var/lib/sonarr";
          user = "sonarr";
          group = "sonarr";
          mode = "u=rwx,g=,o=";
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/sonarr 0700 sonarr sonarr -"
    ];

    users.groups.media = { };
    users.users.sonarr.extraGroups = [ "media" ];
  };
}
