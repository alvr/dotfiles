{ config, lib, ... }:
let
  cfg = config.dot.hm.security.sops;
in
{
  options.dot.hm.security.sops = {
    enable = lib.mkEnableOption "Enable SOPS home-manager security";
    ageFile = lib.mkOption {
      type = lib.types.str;
      default = ".age-keys.txt";
    };
    secretsFile = lib.mkOption {
      type = lib.types.str;
      default = "secrets.yaml";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets/users/${config.home.username}/${cfg.secretsFile};
      age.keyFile = "/nix/persist/users/${config.home.username}/${cfg.ageFile}";
      age.generateKey = true;
      gnupg.sshKeyPaths = [ ];
    };

    dot.hm.system.persistence.files = [ cfg.ageFile ];
  };
}
