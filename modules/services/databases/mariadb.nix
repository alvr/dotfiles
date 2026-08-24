{ inputs, ... }:
{
  flake.modules.nixos.mariadb =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dot.services.mariadb;

      databasesWithPassword = builtins.filter (db: db.passwordFile != null) cfg.databases;
      passwordUpdater = pkgs.writeShellScriptBin "mariadb-update-passwords" ''
        set -euo pipefail

        ${lib.concatStringsSep "\n\n" (
          map (db: ''
            DB_PASSWORD=$(cat ${db.passwordFile} | tr -d '\n')
            echo "ALTER USER '${db.name}'@'localhost' IDENTIFIED BY '$DB_PASSWORD'; FLUSH PRIVILEGES;" | ${pkgs.mariadb_118}/bin/mariadb
          '') databasesWithPassword
        )}
      '';
    in
    {
      options.dot.services.mariadb = {
        databases = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Name of the database and associated user";
                };
                passwordFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "Path to the secret file containing the password for this user";
                };
              };
            }
          );
          default = [ ];
          description = ''
            List of databases to be created with associated users.
            Each user will have all permissions on their database.
            If passwordFile is provided, the user's password will be set from the secret file.
          '';
        };
      };

      config = {
        services = {
          mysql = {
            enable = true;
            ensureDatabases = map (db: db.name) cfg.databases;
            package = pkgs.mariadb_118;
            settings = {
              mysqld = {
                bind-address = "127.0.0.1";
              };
            };

            ensureUsers = map (db: {
              inherit (db) name;
              ensurePermissions = {
                "${db.name}.*" = "ALL PRIVILEGES";
              };
            }) cfg.databases;
          };

          mysqlBackup = {
            enable = true;
            location = "/data/backups/mariadb";
            calendar = "*-*-* 02:00:00";
            databases = map (db: db.name) cfg.databases;
          };

          prometheus.exporters.mysqld = lib.mkIf config.services.prometheus.enable {
            enable = true;
            configFile = config.sops.templates."mariadb/exporter.cnf".path;
            inherit (config.services.mysql) user group;
          };
        };

        systemd.services.mariadb-password-updater = lib.mkIf (databasesWithPassword != [ ]) {
          description = "Update MariaDB user passwords from secret files";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${passwordUpdater}/bin/mariadb-update-passwords";
            RemainAfterExit = true;
          };
          after = [ "mysql.service" ];
          wants = [ "mysql.service" ];
          partOf = [ "mysql.service" ];
          wantedBy = [ "multi-user.target" ];
        };

        dot.services.prometheus.scrape.mysqld = lib.mkIf config.services.prometheus.enable {
          inherit (config.services.prometheus.exporters.mysqld) port;
        };

        dot.system.persistence.directories = [
          {
            directory = "/var/lib/mysql";
            user = "mysql";
            group = "mysql";
            mode = "u=rwx,g=,o=";
          }
        ];

        sops = lib.mkIf config.services.prometheus.enable {
          secrets."mariadb/exporter-password" = {
            sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/mariadb.yaml";
            restartUnits = [ "prometheus-mysqld-exporter.service" ];
          };

          templates."mariadb/exporter.cnf" = {
            content = ''
              [client]
              user=exporter
              password=${config.sops.placeholder."mariadb/exporter-password"}
              socket=/run/mysqld/mysqld.sock
            '';
            owner = "mysql";
            group = "mysql";
            mode = "0400";
          };
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/mysql 0700 mysql mysql -"
          "d /data/backups/mariadb 0744 mysql mysql -"
        ];
      };
    };
}
