{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.calibre;
  cw = config.services.calibre-web;

  subdomain = "books";
  port = 8083;

  emptyMetadataDB = pkgs.fetchurl {
    url = "https://github.com/janeczku/calibre-web/raw/refs/tags/0.6.25/library/metadata.db";
    hash = "sha256-+sL34370vA+ylV6aP2EmBHB9TvVzr1wovXqDaTOfS9Q=";
  };
in
{
  options.dot.services.calibre = {
    enable = lib.mkEnableOption "Enable Calibre Web service";
  };

  config = lib.mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      listen.port = port;
      package = pkgs.calibre-web.overridePythonAttrs (old: {
        dependencies = old.dependencies ++ old.optional-dependencies.kobo;
      });

      options = {
        enableBookConversion = true;
        enableBookUploading = true;
        calibreLibrary = "/media/calibre";
        reverseProxyAuth.enable = true;
        reverseProxyAuth.header = "Authorization";
      };
    };

    dot.services = {
      backup.include = [ "/media/calibre" ];
      cloudflared.subdomains = [ subdomain ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config = {
            locations."/".proxyWebsockets = true;
            locations."/kobo" = {
              proxyPass = "http://localhost:${toString port}/kobo";
              extraConfig = ''
                auth_request off;
                proxy_buffer_size 128k;
                proxy_buffers 4 256k;
                proxy_busy_buffers_size 256k;
              '';
            };
          };
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/calibre-web";
        user = "calibre-web";
        group = "calibre-web";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."calibre/env" = {
      sopsFile = ../../secrets/services/calibre.yaml;
      owner = "calibre-web";
      group = "calibre-web";
      mode = "0400";
    };

    systemd.services = {
      calibre-web-init-db = {
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "60";
        };
        wantedBy = [ "multi-user.target" ];
        before = [ "calibre-web.service" ];

        script = ''
          set -euo pipefail
          if [ ! -f ${cw.options.calibreLibrary}/metadata.db ]; then
            install -Dm666 ${emptyMetadataDB} ${cw.options.calibreLibrary}/metadata.db
            chown -R ${cw.user}:${cw.group} ${cw.options.calibreLibrary}
          fi
        '';
      };

      calibre-web-init-admin-password = {
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "60";
          EnvironmentFile = config.sops.secrets."calibre/env".path;
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "calibre-web.service" ];
        requires = [ "calibre-web.service" ];

        path = [ cw.package ];

        script =
          let
            dataDir = "/var/lib/${cw.dataDir}";
          in
          ''
            set -euo pipefail
            calibre-web -p ${dataDir}/app.db -g ${dataDir}/gdrive.db -s "alvr:$ADMIN_PASSWORD"
          '';
      };
    };

    systemd.tmpfiles.rules = [
      "d /media/calibre 0700 calibre-web calibre-web -"
      "d /var/lib/calibre-web 0700 calibre-web calibre-web -"
    ];
  };
}
