{ config, lib, ... }:
let
  cfg = config.dot.services.jackett;

  subdomain = "jackett";
  port = 9669;
in
{
  options.dot.services.jackett = {
    enable = lib.mkEnableOption "Enable Jackett service";
  };

  config = lib.mkIf cfg.enable {
    services.jackett = {
      enable = true;
      inherit port;
      dataDir = "/var/lib/jackett";
    };

    dot.services = {
      nginx.hosts = [
        {
          inherit subdomain port;
          internal = true;

          oidc.allowedGroups = [ "jackett_users" ];
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/jackett";
        user = "jackett";
        group = "jackett";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.services.jackett = {
      requires = [ "nginx.service" ];
      after = [ "nginx.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/jackett 0700 jackett jackett -"
    ];
  };
}
