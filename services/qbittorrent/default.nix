{ config, lib, ... }:
let
  cfg = config.dot.services.qbittorrent;
in
{
  options.dot.services.qbittorrent = {
    enable = lib.mkEnableOption "Enable qBittorrent service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      qbittorrent = {
        enable = true;
        openFirewall = true;
        webuiPort = 9098;

        serverConfig = {
          LegalNotice.Accepted = true;
          Core.AutoDeleteAddedTorrentFile = "IfAdded";
          Network.PortForwardingEnabled = false;
          BitTorrent.Session = {
            AddTorrentStopped = false;
            AlternativeGlobalDLSpeedLimit = 3072;
            AlternativeGlobalUPSpeedLimit = 1024;
            BTProtocol = "TCP";
            DefaultSavePath = "/data/media-center/downloads/completed/";
            DisableAutoTMMByDefault = false;
            DisableAutoTMMTriggers.CategorySavePathChanged = false;
            DisableAutoTMMTriggers.DefaultSavePathChanged = false;
            GlobalDLSpeedLimit = 307200;
            GlobalMaxInactiveSeedingMinutes = 43800;
            GlobalMaxRatio = 2;
            GlobalMaxSeedingMinutes = 10080;
            GlobalUPSpeedLimit = 102400;
            IgnoreSlowTorrentsForQueueing = true;
            MaxActiveCheckingTorrents = 2;
            MaxActiveDownloads = 5;
            MaxActiveTorrents = 20;
            MaxActiveUploads = 15;
            MaxConnections = 600;
            MaxUploads = 200;
            Port = 20793;
            Preallocation = true;
            QueueingSystemEnabled = true;
            ShareLimitAction = "Stop";
            SlowTorrentsDownloadRate = 40;
            SlowTorrentsUploadRate = 40;
            SubcategoriesEnabled = true;
            TempPath = "/data/media-center/downloads/incomplete/";
            TempPathEnabled = true;
          };
          Preferences.WebUI = {
            CSRFProtection = false;
            ClickjackingProtection = false;
            HostHeaderValidation = false;
            Password_PBKDF2 = "@ByteArray(7dHRrfBf1tKMG17BiuTziw==:Wnu43L8yXNIMDs6xQue1JF84k/VbTiolKpMAwx3ELx9dYandNz7CPSLoiNTju4xjrTmXYxSE02z91H89IX2oTA==)";
            SecureCookie = false;
            Username = "alvr";
          };
        };
      };

      caddy.virtualHosts."qb.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:9098
      '';

      cloudflared.tunnels.apeiron.ingress."qb.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "qb.alvr.dev";
          originServerName = "qb.alvr.dev";
        };
      };

    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/qBittorrent";
        user = "qbittorrent";
        group = "qbittorrent";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/qBittorrent 0700 qbittorrent qbittorrent -"

      "d /data/media-center/downloads 2770 qbittorrent media -"

      "d /data/media-center/downloads/completed 2770 qbittorrent media -"
      "Z /data/media-center/downloads/completed 2770 qbittorrent media -"

      "d /data/media-center/downloads/incomplete 2770 qbittorrent media -"
      "Z /data/media-center/downloads/incomplete 2770 qbittorrent media -"
    ];

    users.groups.media = { };
    users.users.qbittorrent.extraGroups = [ "media" ];
  };
}
