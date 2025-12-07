{ config, lib, ... }:
let
  cfg = config.dot.services.radarr;
in
{
  options.dot.services.radarr = {
    enable = lib.mkEnableOption "Enable Radarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      radarr = {
        enable = true;
        dataDir = "/var/lib/radarr";
      };

      nginx.virtualHosts."radarr.alvr.dev" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:7878";
      };
    };

    dot = {
      services.cloudflared.ingress = [ "radarr.alvr.dev" ];

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
