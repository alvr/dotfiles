{
  config,
  lib,
  pkgs,
  ...
}:
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
        package = pkgs.unstable.radarr;
      };

      cloudflared.tunnels.apeiron.ingress."radarr.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "radarr.alvr.dev";
          originServerName = "radarr.alvr.dev";
        };
      };

      traefik.dynamicConfigOptions.http = {
        services.radarr.loadBalancer.servers = [
          { url = "http://localhost:7878"; }
        ];

        routers.radarr = {
          entryPoints = [ "websecure" ];
          middlewares = [ "secure-headers" ];
          rule = "Host(`radarr.alvr.dev`)";
          service = "radarr";
          tls.certResolver = "letsencrypt";
        };
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/radarr";
        user = "radarr";
        group = "radarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/radarr 0700 radarr radarr -"
    ];

    users.groups.media = { };
    users.users.radarr.extraGroups = [ "media" ];
  };
}
