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
        ensureDatabases = cfg.databases;
        initialScript = config.sops.templates."init.sql".path;
        package = pkgs.postgresql_18;
        authentication = pkgs.lib.mkOverride 10 ''
          # type    database    DBuser    origin-address    auth-method
            local   all         all                         trust
            host    all         all       127.0.0.1/32      trust
            host    all         all       ::1/128           trust
        '';

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

      pgadmin = {
        enable = true;
        initialEmail = "alvaro@alvr.dev";
        initialPasswordFile = config.sops.secrets."pgadmin/password".path;
        openFirewall = true;
        package = pkgs.pgadmin4;
        port = 5435;
      };
    };

    dot.system.persistence.directories = [
      "/var/lib/pgadmin"
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops = {
      secrets."postgres/password" = {
        sopsFile = ../../secrets/services/postgres.yaml;
        owner = "postgres";
        group = "postgres";
        mode = "0400";
        restartUnits = [ "postgresql.service" ];
      };

      secrets."pgadmin/password" = {
        sopsFile = ../../secrets/services/pgadmin.yaml;
        owner = "pgadmin";
        group = "pgadmin";
        mode = "0400";
        restartUnits = [ "pgadmin.service" ];
      };

      templates."init.sql" = {
        content = ''
          DO $$
          DECLARE
            new_password text := '${config.sops.placeholder."postgres/password"}';
          BEGIN
            EXECUTE format('ALTER ROLE postgres WITH PASSWORD %L', new_password);
          END
          $$;
        '';
        owner = "postgres";
        group = "postgres";
        mode = "0400";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/postgresql 0700 postgres postgres -"
      "d /data/backups/postgresql 0744 postgres postgres -"
    ];
    
    # Disable pgAdmin DynamicUser
    systemd.services.pgadmin.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "pgadmin";
      Group = lib.mkForce "pgadmin";
    };

    users.groups.pgadmin = { };
    users.users.pgadmin = {
      home = "/var/lib/pgadmin";
      group = "pgadmin";
      isSystemUser = true;
    };
  };
}
