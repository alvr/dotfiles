{ config, lib, ... }:
{
  options.home-modules.persistence = {
    directories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = {
    home.persistence."/nix/persist/users/${config.home.username}" = {
      allowOther = false;

      directories = [
        ".ssh"
      ]
      ++ config.home-modules.persistence.directories;

      files = [
        ".age-keys.txt"
      ]
      ++ config.home-modules.persistence.files;
    };
  };
}
