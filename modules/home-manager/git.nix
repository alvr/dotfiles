{ config, lib, ... }:
let
  cfg = config.dot.hm.programs.git;
in
{
  options.dot.hm.programs.git = {
    enable = lib.mkEnableOption "Enable Git home-manager program";
    username = lib.mkOption {
      type = lib.types.str;
    };
    email = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = cfg.username;
      userEmail = cfg.email;

      extraConfig = {
        init.defaultBranch = "main";
        help.autocorrect = 1;
        color.ui = "auto";
        push.default = "simple";
        credential.helper = "store";
      };

      aliases = {
        co = "checkout";
        ci = "commit";
        st = "status";
        br = "branch";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
  };
}
