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
    enable = lib.mkEnableOption "Enable Jellyfin service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      jellyfin = {
        enable = true;
        openFirewall = true;
      };

      caddy.virtualHosts."watch.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:8096
      '';

      cloudflared.tunnels.apeiron.ingress."watch.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "watch.alvr.dev";
          originServerName = "watch.alvr.dev";
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
        libva-vdpau-driver
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
