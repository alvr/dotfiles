{ inputs, ... }:
let
  passwordInitSql = passwordFile: ''
    SELECT format('ALTER ROLE postgres WITH PASSWORD %L', pg_read_file('${passwordFile}'))
    \gexec
  '';
in
{
  flake.modules.nixos.postgresql =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dot.services.postgresql;
    in
    {
      options.dot.services.postgresql = {
        databases = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            List of PostgreSQL databases to be created.
            Each database will have a user with the same name and be owned by that user.
          '';
        };
      };

      config = {
        services = {
          postgresql = {
            enable = true;
            ensureDatabases = cfg.databases;
            package = pkgs.postgresql_18;
            authentication = pkgs.lib.mkOverride 10 ''
              # type    database    DBuser    origin-address    auth-method
                local   all         all                         peer
                host    all         all       127.0.0.1/32      scram-sha-256
                host    all         all       ::1/128           scram-sha-256
            '';

            ensureUsers = map (db: {
              name = db;
              ensureDBOwnership = true;
            }) cfg.databases;
          };

          postgresqlBackup = {
            enable = true;
            backupAll = true;
            location = "/data/backups/postgresql";
            startAt = "*-*-* 02:00:00";
          };

          prometheus.exporters.postgres = lib.mkIf config.services.prometheus.enable {
            enable = true;
          };
        };

        dot = {
          services = {
            prometheus.scrape.postgres = lib.mkIf config.services.prometheus.enable {
              inherit (config.services.prometheus.exporters.postgres) port;
            };
            restic.exclude = [ "/nix/persist/var/lib/postgresql" ];
          };

          system.persistence.directories = [
            {
              directory = "/var/lib/postgresql";
              user = "postgres";
              group = "postgres";
              mode = "u=rwx,g=,o=";
            }
          ];
        };

        sops.secrets."postgres/password" = {
          sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/postgres.yaml";
          owner = "postgres";
          group = "postgres";
          mode = "0400";
          restartUnits = [ "postgresql-setup.service" ];
        };

        systemd.services.postgresql-setup.postStart = ''
          psql -X -v ON_ERROR_STOP=1 -d postgres -f ${
            pkgs.writeText "postgresql-init.sql" (passwordInitSql config.sops.secrets."postgres/password".path)
          }
        '';

        systemd.tmpfiles.rules = [
          "d /var/lib/postgresql 0700 postgres postgres -"
          "d /data/backups/postgresql 0744 postgres postgres -"
        ];
      };
    };
}
