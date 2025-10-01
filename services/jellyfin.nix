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
    services.jellyfin = {
      enable = true;
      openFirewall = true;
      package = pkgs.unstable.jellyfin;
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/jellyfin";
        user = "jellyfin";
        group = "jellyfin";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/jellyfin 0700 jellyfin jellyfin -"
      "Z /var/lib/jellyfin - jellyfin jellyfin -"
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
