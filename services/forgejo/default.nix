{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.forgejo;

  mkRunnerInstance =
    {
      labels,
      enable ? true,
    }:
    {
      inherit enable labels;
      tokenFile = config.sops.secrets."runner-token".path;
      url = "https://git.alvr.dev";
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
            DOMAIN = "git.alvr.dev";
            HTTP_PORT = 5245;
            ROOT_URL = "https://git.alvr.dev/";
          };
        };
      };

      gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances = lib.mapAttrs (name: value: mkRunnerInstance value // { inherit name; }) {
          docker.labels = [
            "alpine-latest:docker://node:lts-alpine"
            "ubuntu-latest:docker://node:lts-bookworm-slim"
          ];
          host.labels = [ "self:host" ];
        };
      };

      caddy.virtualHosts."git.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:5245
      '';

      cloudflared.tunnels.apeiron.ingress."git.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "git.alvr.dev";
          originServerName = "git.alvr.dev";
        };
      };
    };

    dot.services.postgresql.databases = [ "forgejo" ];

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/forgejo";
        user = "forgejo";
        group = "forgejo";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."runner-token" = {
      format = "dotenv";
      sopsFile = ../../secrets/services/forgejo-runner.env;
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
