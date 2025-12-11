{ config, lib, ... }:
let
  cfg = config.dot.services.jellyseerr;

  subdomain = "seerr";
  port = 5055;
in
{
  options.dot.services.jellyseerr = {
    enable = lib.mkEnableOption "Enable Jellyseerr service";
  };

  config = lib.mkIf cfg.enable {
    services.jellyseerr = {
      enable = true;
      configDir = "/var/lib/jellyseerr";
      inherit port;
    };

    dot = {
      services.cloudflared.subdomains = [ subdomain ];
      services.nginx.services = [
        { inherit subdomain port; }
      ];

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
