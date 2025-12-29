{
  config,
  consts,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.forgejo;

  subdomain = "git";
  port = 5245;
  url = "${subdomain}.${consts.domain}";

  mkRunnerInstance =
    {
      labels,
      enable ? true,
    }:
    {
      inherit enable labels;
      tokenFile = config.sops.secrets."forgejo-runner/env".path;
      url = "https://${url}";
    };
in
{
  options.dot.services.forgejo = {
    enable = lib.mkEnableOption "Enable Forgejo service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      forgejo = {
        enable = true;
        package = pkgs.forgejo;
        repositoryRoot = "/data/forgejo/repositories";
        database.type = "postgres";

        dump = {
          age = "14d";
          backupDir = "/data/backups/forgejo";
          enable = true;
          interval = "02:05";
          type = "tar.zst";
        };

        lfs = {
          enable = true;
          contentDir = "/data/forgejo/lfs";
        };

        settings = {
          actions = {
            ARTIFACT_RETENTION_DAYS = 30;
            DEFAULT_ACTIONS_URL = "github";
            ENABLED = true;
          };

          repository = {
            ENABLE_ARCHIVE = false;
            DISABLE_DOWNLOAD_SOURCE_ARCHIVES = true;
          };

          service.DISABLE_REGISTRATION = true;

          server = {
            DISABLE_SSH = true;
            DOMAIN = url;
            HTTP_PORT = port;
            ROOT_URL = "https://${url}/";
          };
        };
      };

      gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances = lib.mapAttrs (name: value: mkRunnerInstance value // { inherit name; }) {
          docker.labels = [
            "alpine-latest:docker://node:lts-alpine"
            "ubuntu-latest:docker://node:lts-trixie-slim"
          ];
          host.labels = [ "self-hosted:host" ];
        };
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "forgejo" ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/" = {
            proxyWebsockets = true;
            extraConfig = "client_max_body_size 512M;";
          };
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/forgejo";
        user = "forgejo";
        group = "forgejo";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."forgejo-runner/env" = {
      sopsFile = ../../secrets/services/forgejo-runner.yaml;
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/forgejo 0700 forgejo forgejo -"
      "d /data/backups/forgejo 0744 forgejo forgejo -"
      "d /data/forgejo/lfs 0700 forgejo forgejo -"
      "d /data/forgejo/repositories 0700 forgejo forgejo -"
    ];
  };
}
