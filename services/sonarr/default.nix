{ config, lib, ... }:
let
  cfg = config.dot.services.sonarr;
in
{
  options.dot.services.sonarr = {
    enable = lib.mkEnableOption "Enable Sonarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      sonarr = {
        enable = true;
        dataDir = "/var/lib/sonarr";
      };

      nginx.virtualHosts."sonarr.alvr.dev" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:8989";
      };
    };

    dot = {
      services.cloudflared.ingress = [ "sonarr.alvr.dev" ];

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
