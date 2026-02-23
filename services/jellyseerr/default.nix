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
      inherit port;
    };

    dot = {
      services.cloudflared.subdomains = [ subdomain ];
      services.nginx.hosts = [
        { inherit subdomain port; }
      ];

      system.persistence.directories = [
        "/var/lib/private/jellyseerr"
      ];
    };

    systemd.services.jellyseerr = {
      requires = [ "nginx.service" ];
      after = [ "nginx.service" ];
    };
  };
}
