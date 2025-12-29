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

    dot = {
      services.cloudflared.subdomains = [ subdomain ];
      services.nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/".proxyWebsockets = true;
          config.locations."/api" = {
            proxyPass = "http://${subdomain}";
            extraConfig = "auth_basic off;";
          };
        }
      ];

      system.persistence.directories = [
        {
          directory = "/var/lib/prowlarr";
          user = "prowlarr";
          group = "prowlarr";
          mode = "u=rwx,g=,o=";
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/prowlarr 0700 prowlarr prowlarr -"
    ];

    # Disable DynamicUser
    systemd.services.prowlarr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "prowlarr";
      Group = lib.mkForce "prowlarr";
    };

    users.groups.prowlarr = { };
    users.users.prowlarr = {
      home = "/var/lib/prowlarr";
      group = "prowlarr";
      isSystemUser = true;
    };
  };
}
