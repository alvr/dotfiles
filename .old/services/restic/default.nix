{ config, lib, ... }:
let
  cfg = config.dot.services.backup;

  destinations = [
    "onedrive"
    "r2"
  ];

  mkBackup = name: {
    initialize = true;
    checkOpts = [ "--read-data-subset=5%" ];
    rcloneConfigFile = config.sops.secrets."restic/${name}/config".path;
    repositoryFile = config.sops.secrets."restic/${name}/repo".path;
    passwordFile = config.sops.secrets."restic/${name}/password".path;

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

  mkSecrets =
    name:
    let
      restic-secret = {
        sopsFile = ../../secrets/services/restic.yaml;
        mode = "0400";
      };
    in
    {
      "restic/${name}/config" = restic-secret;
      "restic/${name}/repo" = restic-secret;
      "restic/${name}/password" = restic-secret;
    };
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
    services.restic.backups = lib.genAttrs destinations mkBackup;

    sops.secrets = lib.foldl' (acc: name: acc // mkSecrets name) { } destinations;
  };
}
