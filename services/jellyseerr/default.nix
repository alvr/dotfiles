{ config, lib, ... }:
let
  cfg = config.dot.services.jellyseerr;
in
{
  options.dot.services.jellyseerr = {
    enable = lib.mkEnableOption "Enable Jellyseerr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      jellyseerr = {
        enable = true;
        configDir = "/var/lib/jellyseerr";
      };

      nginx.virtualHosts."seerr.alvr.dev" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:5055";
      };
    };

    dot = {
      services.cloudflared.ingress = [ "seerr.alvr.dev" ];

      system.persistence.directories = [
        {
          directory = "/var/lib/jellyseerr";
          user = "jellyseerr";
          group = "jellyseerr";
          mode = "u=rwx,g=,o=";
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/jellyseerr 0700 jellyseerr jellyseerr -"
    ];

    # Disable DynamicUser
    systemd.services.jellyseerr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "jellyseerr";
      Group = lib.mkForce "jellyseerr";
    };

    users.groups.jellyseerr = { };
    users.users.jellyseerr = {
      home = "/var/lib/jellyseerr";
      group = "jellyseerr";
      isSystemUser = true;
    };
  };
}
