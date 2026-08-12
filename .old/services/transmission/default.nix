{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.transmission;

  subdomain = "bt";
  port = 9091;
in
{
  options.dot.services.transmission = {
    enable = lib.mkEnableOption "Enable Transmission service";
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      performanceNetParameters = true;
      webHome = "${pkgs.flood-for-transmission}";

      settings = {
        alt-speed-up = 1;
        alt-speed-down = 3;

        speed-limit-down = 10 * 1000;
        speed-limit-down-enabled = true;
        speed-limit-up = 5 * 1000;
        speed-limit-up-enabled = true;

        upload-slots-per-torrent = 200;

        blocklist-url = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
        blocklist-enabled = true;

        download-dir = "/data/media-center/downloads/completed/";
        incomplete-dir = "/data/media-center/downloads/incomplete/";
        incomplete-dir-enabled = true;
        preallocation = 1;
        start-added-torrents = true;
        trash-original-torrent-files = true;
        umask = "022";

        message-level = 2;

        peer-limit-global = 512;
        peer-limit-per-torrent = 128;

        peer-port-random-high = 60660;
        peer-port-random-low = 55660;
        peer-port-random-on-start = true;

        download-queue-enabled = true;
        download-queue-size = 5;
        queue-stalled-enabled = true;
        queue-stalled-minutes = 30;
        seed-queue-enabled = true;
        seed-queue-size = 15;

        rpc-authentication-required = false;
        rpc-bind-address = "127.0.0.1";
        rpc-host-whitelist = "${subdomain}.${consts.domain},127.0.0.*,192.168.1.*,100.93.93.*";
        rpc-host-whitelist-enabled = true;
        rpc-port = port;
        rpc-whitelist = "127.0.0.1";
        rpc-whitelist-enabled = true;
      };
    };

    dot.services = {
      nginx.hosts = [
        {
          inherit subdomain port;
          internal = true;

          oidc.allowedGroups = [ "transmission_users" ];
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/transmission";
        user = "transmission";
        group = "transmission";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd = {
      services.transmission = {
        requires = [ "nginx.service" ];
        after = [ "nginx.service" ];
      };

      services.transmission-blocklist-update = {
        description = "Update Transmission blocklist";
        requires = [ "transmission.service" ];
        after = [ "transmission.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.services.transmission.package}/bin/transmission-remote --blocklist-update";
        };
      };

      timers.transmission-blocklist-update = {
        description = "Run Transmission blocklist every friday at 00:00";
        after = [ "transmission.service" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Fri *-*-* 00:00:00";
          Persistent = true;
        };
      };

      tmpfiles.rules = [
        "d /var/lib/transmission 0700 transmission transmission -"

        "d /data/media-center/downloads 2770 transmission media -"

        "d /data/media-center/downloads/completed 2770 transmission media -"
        "Z /data/media-center/downloads/completed 2770 transmission media -"

        "d /data/media-center/downloads/incomplete 2770 transmission media -"
        "Z /data/media-center/downloads/incomplete 2770 transmission media -"
      ];
    };

    users.groups.media = { };
    users.users.transmission.extraGroups = [ "media" ];
  };
}
