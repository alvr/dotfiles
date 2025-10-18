{
  config,
  lib,
  pkgs,
  ...
}:
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
        package = pkgs.unstable.sonarr;
      };

      cloudflared.tunnels.apeiron.ingress."sonarr.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "sonarr.alvr.dev";
          originServerName = "sonarr.alvr.dev";
        };
      };

      traefik.dynamicConfigOptions.http = {
        services.sonarr.loadBalancer.servers = [
          { url = "http://localhost:8989"; }
        ];

        routers.sonarr = {
          entryPoints = [ "websecure" ];
          middlewares = [ "secure-headers" ];
          rule = "Host(`sonarr.alvr.dev`)";
          service = "sonarr";
          tls.certResolver = "letsencrypt";
        };
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/sonarr";
        user = "sonarr";
        group = "sonarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/sonarr 0700 sonarr sonarr -"
    ];

    users.groups.media = { };
    users.users.sonarr.extraGroups = [ "media" ];
  };
}
