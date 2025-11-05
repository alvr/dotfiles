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
    enable = lib.mkEnableOption "Enable PostgreSQL service";

    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of PostgreSQL databases to be created.
        Each database will have a user with the same name and be owned by that user.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      postgresql = {
        enable = true;
        package = pkgs.unstable.postgresql_18;
        authentication = pkgs.lib.mkOverride 10 ''
          # type    database    DBuser    origin-address    auth-method
            local   all         all                         trust
        '';

        ensureDatabases = cfg.databases;
        ensureUsers = builtins.map (db: {
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
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/postgresql 0700 postgres postgres -"
      "d /data/backups/postgresql 0744 postgres postgres -"
    ];
  };
}
