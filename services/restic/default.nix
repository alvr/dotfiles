{ config, lib, ... }:
let
  cfg = config.dot.services.restic;
in
{
  options.dot.services.restic = {
    enable = lib.mkEnableOption "Enable restic service";
  };

  config = lib.mkIf cfg.enable {
    services.restic.backups.onedrive = {
      initialize = true;
      rcloneConfigFile = config.sops.secrets."restic/config".path;
      repositoryFile = config.sops.secrets."restic/repo".path;
      passwordFile = config.sops.secrets."restic/password".path;

      checkOpts = [ "--read-data-subset=5%" ];

      paths = [
        "/data/backups"
        "/nix/persist"
      ];

      exclude = [
        "/nix/persist/dotfiles"
        "/nix/persist/lost+found"
        "/nix/persist/var/lib/systemd"
        "/nix/persist/var/log"
      ];

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
