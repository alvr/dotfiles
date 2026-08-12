{ config, lib, ... }:
let
  cfg = config.dot.hm.system.persistence;
in
{
  options.dot.hm.system.persistence = {
    enable = lib.mkEnableOption "Enable persistence home-manager system";
    directories = lib.mkOption {
      type = lib.types.listOf (
        lib.types.oneOf [
          lib.types.str
          (lib.types.attrsOf lib.types.anything)
        ]
      );
      default = [ ];
    };
    files = lib.mkOption {
      type = lib.types.listOf (
        lib.types.oneOf [
          lib.types.str
          (lib.types.attrsOf lib.types.anything)
        ]
      );
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.persistence."/nix/persist/users/${config.home.username}" = {
      inherit (cfg) directories files;
    };
  };
}
