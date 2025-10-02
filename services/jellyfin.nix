{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.jellyfin;
in
{
  options.dot.services.jellyfin = {
    enable = lib.mkEnableOption "Enable Jellyfin service" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      jellyfin = {
        enable = true;
        openFirewall = true;
        package = pkgs.unstable.jellyfin;
      };

      cloudflared.tunnels.apeiron-internal.ingress."watch.alvr.dev" = {
        service = "http://localhost:8096";
        originRequest = {
          originServerName = "watch.alvr.dev";
        };
      };

      traefik.dynamicConfigOptions.http = {
        services = {
          jellyfin.loadBalancer.servers = [
            {
              url = "http://localhost:8096";
            }
          ];
        };

        routers.jellyfin = {
          entryPoints = [ "websecure" ];
          rule = "Host(`watch.alvr.dev`)";
          service = "jellyfin";
          tls.certResolver = "letsencrypt";
        };
      };

      xserver.videoDrivers = [ "amdgpu" ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/jellyfin";
        user = "jellyfin";
        group = "jellyfin";
        mode = "u=rwx,g=,o=";
      }
    ];

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        libva
        libvdpau-va-gl
        vaapiVdpau
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/jellyfin 0700 jellyfin jellyfin -"
      "d /data/media-center 2770 root media -"
      "d /data/media-center/Anime 2770 root media -"
      "d /data/media-center/Anime/TV 2770 root media -"
      "d /data/media-center/Anime/Movies 2770 root media -"
      "d /data/media-center/Shows 2770 root media -"
      "d /data/media-center/Movies 2770 root media -"
    ];

    users.groups.media = { };
    users.users.jellyfin.extraGroups = [ "media" ];
  };
}
