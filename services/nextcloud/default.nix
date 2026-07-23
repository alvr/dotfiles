{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.nextcloud;

  subdomain = "cloud";
in
{
  options.dot.services.nextcloud = {
    enable = lib.mkEnableOption "Enable Nextcloud service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      nextcloud = {
        enable = true;
        package = pkgs.nextcloud34;

        caching.redis = true;
        configureRedis = true;
        datadir = "/data/nextcloud";
        hostName = "${subdomain}.${consts.domain}";
        https = true;
        phpPackage = pkgs.php85;

        config = {
          adminuser = "alvr";
          adminpassFile = config.sops.secrets."nextcloud/admin-pass".path;
          dbtype = "pgsql";
          dbname = "nextcloud";
          dbhost = "/run/postgresql";
          dbuser = "nextcloud";
          dbpassFile = config.sops.secrets."nextcloud/db-pass".path;
        };

        extraApps = {
          inherit (config.services.nextcloud.package.packages.apps)
            bookmarks
            calendar
            contacts
            deck
            mail
            memories
            onlyoffice
            previewgenerator
            recognize
            user_oidc
            tasks
            ;
        };

        settings = {
          default_phone_region = "ES";
          hide_login_form = true;
          overwriteprotocol = "https";
          overwritecondaddr = false;
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];
          maintenance_window_start = 2;
        };

        poolSettings = {
          pm = "dynamic";
          "pm.max_children" = "16";
          "pm.max_requests" = 500;
          "pm.max_spare_servers" = "12";
          "pm.min_spare_servers" = "4";
          "pm.process_idle_timeout" = "10s";
          "pm.start_servers" = "4";
        };

        phpOptions = {
          "opcache.interned_strings_buffer" = "32";
          "opcache.jit" = "1255";
          "opcache.jit_buffer_size" = "8M";
        };
      };

      prometheus.exporters.nextcloud = lib.mkIf config.dot.services.prometheus.enable {
        enable = true;
        group = "nextcloud";
        user = "nextcloud";
        url = "https://${config.services.nextcloud.hostName}";
        username = config.services.nextcloud.config.adminuser;
        passwordFile = config.sops.secrets."nextcloud/admin-pass".path;
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "nextcloud" ];
      prometheus.scrape.nextcloud = lib.mkIf config.dot.services.prometheus.enable {
        inherit (config.services.prometheus.exporters.nextcloud) port;
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/nextcloud";
        user = "nextcloud";
        group = "nextcloud";
        mode = "u=rwx,g=,o=";
      }
    ];

    services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
      forceSSL = true;
      useACMEHost = consts.domain;
    };

    sops.secrets =
      let
        nextcloud-secret = {
          sopsFile = ../../secrets/services/nextcloud.yaml;
          owner = "nextcloud";
          group = "nextcloud";
          mode = "0400";
          restartUnits = [ "nextcloud-setup.service" ];
        };
      in
      {
        "nextcloud/admin-pass" = nextcloud-secret;
        "nextcloud/db-pass" = nextcloud-secret;
      };

    systemd = {
      services.nextcloud-mimetype-migrations =
        let
          inherit (config.services.nextcloud) occ;
        in
        {
          after = [
            "nextcloud-setup.service"
            "postgresql.service"
            "redis-nextcloud.service"
          ];
          script = "${occ}/bin/nextcloud-occ maintenance:repair --include-expensive";
          serviceConfig.Type = "oneshot";
        };

      timers.nextcloud-mimetype-migrations = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Fri *-*-* 04:00:00";
          Persistent = true;
        };
      };

      tmpfiles.rules = [
        "d /var/lib/nextcloud 0700 nextcloud nextcloud -"
      ];
    };
  };
}
