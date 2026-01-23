{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.services.booklore;

  subdomain = "books";
  port = 6060;
  stateDir = "/var/lib/booklore";
  dataDir = "/data/booklore";
in
{
  options.dot.services.booklore = {
    enable = lib.mkEnableOption "Enable BookLore service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.booklore = {
      image = "ghcr.io/booklore-app/booklore:v1.18.5";
      autoStart = true;
      environment = {
        USER_ID = "0";
        GROUP_ID = "0";
        BOOKLORE_PORT = "${toString port}";
        TZ = config.time.timeZone;
      };
      environmentFiles = [
        config.sops.secrets."booklore/env".path
        config.sops.templates."booklore/db-password".path
      ];
      extraOptions = [
        "--network=host"
        "--add-host"
        "host.containers.internal:host-gateway"
      ];
      ports = [ "${toString port}:${toString port}" ];
      volumes = [
        "${stateDir}:/app/data:Z"
        "${dataDir}/books:/books:Z"
        "${dataDir}/drops:/bookdrop:Z"
      ];
    };

    dot.services = {
      backup.include = [ "/data/booklore" ];
      cloudflared.subdomains = [ subdomain ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/".proxyWebsockets = true;
        }
      ];
      mariadb.databases = [
        {
          name = "booklore";
          passwordFile = config.sops.secrets."booklore/db-password".path;
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = stateDir;
        user = "booklore";
        group = "booklore";
        mode = "u=rwx,g=rx,o=";
      }
    ];

    sops = {
      secrets."booklore/db-password" = {
        sopsFile = ../../secrets/services/booklore.yaml;
        restartUnits = [
          "mysql.service"
          "podman-booklore.service"
        ];
      };

      secrets."booklore/env" = {
        sopsFile = ../../secrets/services/booklore.yaml;
        owner = "booklore";
        group = "booklore";
        mode = "0400";
        restartUnits = [ "podman-booklore.service" ];
      };

      templates."booklore/db-password" = {
        content = ''
          DATABASE_PASSWORD=${config.sops.placeholder."booklore/db-password"}
        '';
      };
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0700 booklore booklore -"
      "d ${dataDir}/books 0700 booklore booklore -"
      "d ${dataDir}/drops 0700 booklore booklore -"
    ];

    users = {
      groups.booklore = { };
      users.booklore = {
        createHome = true;
        isSystemUser = true;
        group = "booklore";
        home = stateDir;
        extraGroups = [ "media" ];
      };
    };
  };
}
