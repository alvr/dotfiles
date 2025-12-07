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

      nginx.virtualHosts."watch.alvr.dev" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:8096";
      };

      xserver.videoDrivers = [ "amdgpu" ];
    };

    dot = {
      services.cloudflared.ingress = [ "watch.alvr.dev" ];

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
