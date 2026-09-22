{
  flake.modules.nixos.jellyfin =
    { config, lib, ... }:
    let
      subdomain = "watch";
      port = 8096;
    in
    {
      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };

      dot = {
        services = {
          cloudflared.subdomains = [ subdomain ];
          nginx.hosts = [
            {
              inherit subdomain port;
              config.locations = {
                "/".extraConfig = "proxy_buffering off;";
                "/metrics".return = 403;

                "/socket" = {
                  proxyPass = "http://${subdomain}";
                  proxyWebsockets = true;
                };
              };
            }
          ];
          prometheus.scrape.jellyfin = lib.mkIf config.services.prometheus.enable {
            inherit port;
          };
        };

        system.persistence.directories = [
          {
            directory = "/var/lib/jellyfin";
            user = "jellyfin";
            group = "jellyfin";
            mode = "u=rwx,g=,o=";
          }
        ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/jellyfin 0700 jellyfin jellyfin -"

        "d /data/media-center/library 2770 root media -"

        "d /data/media-center/library/movies 2770 root media -"
        "Z /data/media-center/library/movies 2770 root media -"

        "d /data/media-center/library/shows 2770 root media -"
        "Z /data/media-center/library/shows 2770 root media -"
      ];

      users.groups.media = { };
      users.users.jellyfin.extraGroups = [ "media" ];
    };
}
