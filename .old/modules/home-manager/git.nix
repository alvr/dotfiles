{ config, lib, ... }:
let
  cfg = config.dot.hm.programs.git;
in
{
  options.dot.hm.programs.git = {
    enable = lib.mkEnableOption "Enable Git home-manager program";
    email = lib.mkOption {
      type = lib.types.str;
    };
    name = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;

      settings = {
        color.ui = "auto";
        credential.helper = "store";
        help.autocorrect = 1;
        init.defaultBranch = "main";
        push.default = "simple";

        alias = {
          co = "checkout";
          ci = "commit";
          st = "status";
          br = "branch";
          lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        };

        user = {
          inherit (cfg) email name;
        };
      };
    };
  };
}
