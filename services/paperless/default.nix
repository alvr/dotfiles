{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.paperless;

  subdomain = "papers";
  port = 28981;
in
{
  options.dot.services.paperless = {
    enable = lib.mkEnableOption "Enable Paperless service";
  };

  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      domain = "${subdomain}.${consts.domain}";
      environmentFile = config.sops.secrets."paperless/env".path;
      mediaDir = "/data/paperless/media";
      consumptionDir = "/data/paperless/consume";

      settings = {
        PAPERLESS_DBHOST = "/run/postgresql";
        PAPERLESS_OCR_LANGUAGE = "spa+eng";
        PAPERLESS_TRUSTED_PROXIES = "127.0.0.1/32,::1";
      };
    };

    dot.services = {
      backup.include = [ "/data/paperless" ];
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "paperless" ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations = {
            "/static/" = {
              root = config.services.paperless.package;
              extraConfig = "rewrite ^/(.*)$ /lib/paperless-ngx/$1 break;";
            };
            "= /ws/status" = {
              proxyPass = "http://${subdomain}";
              proxyWebsockets = true;
            };
          };
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/paperless";
        user = "paperless";
        group = "paperless";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."paperless/env" = {
      sopsFile = ../../secrets/services/paperless.yaml;
      owner = "paperless";
      group = "paperless";
      mode = "0400";
      restartUnits = [
        "paperless-scheduler.service"
        "paperless-consumer.service"
        "paperless-web.service"
      ];
    };

    systemd.services.paperless-web = {
      requires = [
        "nginx.service"
        "pocket-id.service"
      ];
      after = [
        "nginx.service"
        "pocket-id.service"
      ];
      serviceConfig = {
        Restart = "always";
        RestartMaxDelaySec = "1min";
        RestartSec = "5s";
        RestartSteps = 5;
      };
    };

    systemd.tmpfiles.rules = [
      "d /data/paperless 0700 paperless paperless -"
      "d /data/paperless/media 0700 paperless paperless -"
      "d /data/paperless/consume 0700 paperless paperless -"
      "d /var/lib/paperless 0700 paperless paperless -"
    ];
  };
}
