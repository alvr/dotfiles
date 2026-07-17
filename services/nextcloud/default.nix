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
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;

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
          mail
          user_oidc
          tasks
          ;
      };

      settings = {
        default_phone_region = "ES";
        overwriteprotocol = "https";
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "nextcloud" ];
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

    systemd.tmpfiles.rules = [
      "d /var/lib/nextcloud 0700 nextcloud nextcloud -"
    ];
  };
}
