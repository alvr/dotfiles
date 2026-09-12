{
  flake.modules.homeManager.git = { config, ... }: {
    programs.git = {
      enable = true;
      settings = {
        color.ui = "auto";
        credential.helper = "cache --timeout=3600";
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
        user = { inherit (config.dot.host.user) email name; };
      };
    };
  };
}
