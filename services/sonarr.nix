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
        settings.server.urlbase = "/sonarr";
      };

      traefik.dynamicConfigOptions.http = {
        services = {
          sonarr.loadBalancer.servers = [
            { url = "http://localhost:8989"; }
          ];
        };

        middlewares.strip-sonarr-path.stripPrefix.prefixes = [ "/sonarr" ];

        routers.sonarr = {
          entryPoints = [ "websecure" ];
          rule = "Host(`arr.alvr.dev`) && PathPrefix(`/sonarr`)";
          service = "sonarr";
          tls.certResolver = "letsencrypt";
          middlewares = [ "strip-sonarr-path" ];
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
