{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.qbittorrent;

  subdomain = "qb";
  port = 9098;
in
{
  options.dot.services.qbittorrent = {
    enable = lib.mkEnableOption "Enable qBittorrent service";
  };

  config = lib.mkIf cfg.enable {
    services.qbittorrent = {
      enable = true;
      openFirewall = true;
      webuiPort = port;

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
          AlternativeUIEnabled = true;
          AuthSubnetWhitelist = "127.0.0.0/8";
          AuthSubnetWhitelistEnabled = true;
          CSRFProtection = false;
          ClickjackingProtection = false;
          HostHeaderValidation = false;
          Password_PBKDF2 = "@ByteArray(7dHRrfBf1tKMG17BiuTziw==:Wnu43L8yXNIMDs6xQue1JF84k/VbTiolKpMAwx3ELx9dYandNz7CPSLoiNTju4xjrTmXYxSE02z91H89IX2oTA==)";
          RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
          SecureCookie = false;
          TrustedReverseProxiesList = "127.0.0.1";
          Username = "alvr";
        };
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      nginx.hosts = [
        { inherit subdomain port; }
      ];

      oauth2-proxy.hosts.${subdomain}.allowed_groups = [ "qbittorrent_users" ];
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
