{ config, lib, ... }:
let
  cfg = config.dot.services.prowlarr;
in
{
  options.dot.services.prowlarr = {
    enable = lib.mkEnableOption "Enable Prowlarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      prowlarr.enable = true;

      nginx.virtualHosts."prowlarr.alvr.dev" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:9696";
      };
    };

    dot = {
      services.cloudflared.ingress = [ "prowlarr.alvr.dev" ];

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
