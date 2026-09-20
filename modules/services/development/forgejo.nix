{ inputs, ... }:
{
  flake.modules.nixos.forgejo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      subdomain = "git";
      port = 5245;
      url = "${subdomain}.${config.dot.host.network.domain}";

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
            DEFAULT.APP_NAME = "alvr Git Service";

            actions = {
              ARTIFACT_RETENTION_DAYS = 30;
              DEFAULT_ACTIONS_URL = "github";
              ENABLED = true;
            };

            oauth2_client = {
              ACCOUNT_LINKING = "login";
              ENABLE_AUTO_REGISTRATION = true;
              USERNAME = "nickname";
            };

            repository = {
              DISABLE_DOWNLOAD_SOURCE_ARCHIVES = true;
              ENABLE_ARCHIVE = false;
            };

            "repository.signing" = {
              FORMAT = "ssh";
              SIGNING_KEY = config.sops.secrets."forgejo/ssh-git-sign/pub".path;
              SIGNING_NAME = "alvr-bot";
              SIGNING_EMAIL = "git@${config.dot.host.network.domain}";
              DEFAULT_TRUST_MODEL = "collaborator";
              CRUD_ACTIONS = "always";
              INITIAL_COMMIT = "always";
              MERGES = "always";
              WIKI = "always";
            };

            server = {
              DISABLE_SSH = true;
              DOMAIN = url;
              HTTP_PORT = port;
              ROOT_URL = "https://${url}/";
            };

            service = {
              ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
              DISABLE_REGISTRATION = true;
              ENABLE_BASIC_AUTHENTICATION = false;
              ENABLE_INTERNAL_SIGNIN = false;
              REQUIRE_EXTERNAL_REGISTRATION_PASSWORD = false;
            };

            "service.explore" = {
              REQUIRE_SIGNIN_VIEW = true;
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

      sops.secrets = {
        "forgejo/ssh-git-sign/pub" = {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/forgejo.yaml";
          owner = "forgejo";
          group = "forgejo";
          mode = "0440";
          path = "/var/lib/forgejo/.ssh/ssh-git-sign.pub";
          restartUnits = [ "forgejo.service" ];
        };

        "forgejo/ssh-git-sign/prv" = {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/forgejo.yaml";
          owner = "forgejo";
          group = "forgejo";
          mode = "0400";
          path = "/var/lib/forgejo/.ssh/ssh-git-sign";
          restartUnits = [ "forgejo.service" ];
        };

        "forgejo-runner/env" = {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/forgejo-runner.yaml";
          mode = "0400";
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/forgejo 0700 forgejo forgejo -"
        "d /data/backups/forgejo 0744 forgejo forgejo -"
        "d /data/forgejo/lfs 0700 forgejo forgejo -"
        "d /data/forgejo/repositories 0700 forgejo forgejo -"
      ];
    };
}
