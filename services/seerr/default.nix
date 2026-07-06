{ config, lib, ... }:
let
  cfg = config.dot.services.seerr;

  subdomain = "seerr";
  port = 5055;
in
{
  options.dot.services.seerr = {
    enable = lib.mkEnableOption "Enable Seerr service";
  };

  config = lib.mkIf cfg.enable {
    services.seerr = {
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

    systemd.services.seerr = {
      requires = [ "nginx.service" ];
      after = [ "nginx.service" ];
    };
  };
}
