{ config, lib, ... }:
let
  cfg = config.dot.services.backup;
in
{
  options.dot.services.backup = {
    enable = lib.mkEnableOption "Enable restic service";

    include = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups.onedrive = {
      initialize = true;
      checkOpts = [ "--read-data-subset=5%" ];
      rcloneConfigFile = config.sops.secrets."restic/config".path;
      repositoryFile = config.sops.secrets."restic/repo".path;
      passwordFile = config.sops.secrets."restic/password".path;

      paths = [
        "/data/backups"
        "/nix/persist"
      ]
      ++ cfg.include;

      exclude = [
        "/nix/persist/dotfiles"
        "/nix/persist/lost+found"
        "/nix/persist/var/lib/systemd"
        "/nix/persist/var/log"
      ]
      ++ cfg.exclude;

      pruneOpts = [ "--keep-monthly 14" ];

      timerConfig = {
        OnCalendar = "02:30";
        Persistent = true;
      };
    };

    sops.secrets =
      let
        restic-secret = {
          sopsFile = ../../secrets/services/restic.yaml;
          mode = "0400";
        };
      in
      {
        "restic/config" = restic-secret;
        "restic/repo" = restic-secret;
        "restic/password" = restic-secret;
      };
  };
}
