{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.jellyfin;

  subdomain = "watch";
  port = 8096;
in
{
  options.dot.services.jellyfin = {
    enable = lib.mkEnableOption "Enable Jellyfin service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      jellyfin = {
        enable = true;
        openFirewall = true;
      };

      xserver.videoDrivers = [ "amdgpu" ];
    };

    dot = {
      services.cloudflared.subdomains = [ subdomain ];
      services.nginx.hosts = [
        {
          inherit subdomain port;
          config = {
            locations."/".extraConfig = "proxy_buffering off;";

            locations."/socket" = {
              proxyPass = "http://${subdomain}";
              proxyWebsockets = true;
            };
          };
        }
      ];

      system.persistence.directories = [
        {
          directory = "/var/lib/jellyfin";
          user = "jellyfin";
          group = "jellyfin";
          mode = "u=rwx,g=,o=";
        }
      ];
    };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libva
        libvdpau-va-gl
        libva-vdpau-driver
      ];
    };

    systemd.services.jellyfin = {
      requires = [
        "nginx.service"
        "pocket-id.service"
      ];
      after = [
        "nginx.service"
        "pocket-id.service"
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
