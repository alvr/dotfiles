{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.mariadb;
in
{
  options.dot.services.mariadb = {
    enable = lib.mkEnableOption "Enable MariaDB service";

    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of MariaDB databases to be created.
        Each database will have a user with the same name and be granted full access.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      mysql = {
        enable = true;
        ensureDatabases = cfg.databases;
        package = pkgs.mariadb_118;

        ensureUsers = builtins.map (db: {
          name = db;
          ensureDBOwnership = true;
        }) cfg.databases;
      };

      mysqlBackup = {
        enable = true;
        location = "/data/backups/mariadb";
        calendar = "*-*-* 02:00:00";
        inherit (cfg) databases;
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/mysql";
        user = "mysql";
        group = "mysql";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/mysql 0700 mysql mysql -"
      "d /data/backups/mariadb 0744 mysql mysql -"
    ];
  };
}
