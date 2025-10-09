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
        settings.server.urlbase = "/radarr";
      };

      traefik.dynamicConfigOptions.http = {
        services = {
          radarr.loadBalancer.servers = [
            { url = "http://localhost:7878"; }
          ];
        };

        middlewares.strip-radarr-path.stripPrefix.prefixes = [ "/radarr" ];

        routers.radarr = {
          entryPoints = [ "websecure" ];
          rule = "Host(`arr.alvr.dev`) && PathPrefix(`/radarr`)";
          service = "radarr";
          tls.certResolver = "letsencrypt";
          middlewares = [ "strip-radarr-path" ];
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
