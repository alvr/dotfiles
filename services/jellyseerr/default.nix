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

      caddy.virtualHosts."seerr.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:5055
      '';

      cloudflared.tunnels.apeiron.ingress."seerr.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "seerr.alvr.dev";
          originServerName = "seerr.alvr.dev";
        };
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/jellyseerr";
        user = "jellyseerr";
        group = "jellyseerr";
        mode = "u=rwx,g=,o=";
      }
    ];

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
