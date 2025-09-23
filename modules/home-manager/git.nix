{ config, lib, ... }:
{
  options.home-modules.git = {
    username = lib.mkOption {
      type = lib.types.str;
    };
    email = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    programs.git = {
      enable = true;
      userName = config.home-modules.git.username;
      userEmail = config.home-modules.git.email;

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
