{ self, ... }:
{
  flake.modules = {
    nixos.git = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        gitbutler
        sourcegit
      ];
    };

    homeManager.git =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        catppuccin.lazygit.enable = true;

        programs.git = {
          enable = true;
          package = pkgs.gitFull;
          settings = {
            color.ui = "auto";
            credential.helper = "cache --timeout=3600";
            credential."https://git.alvr.dev".helper = "libsecret";
            help.autocorrect = 1;
            init.defaultBranch = "main";
            push.default = "simple";
            commit.gpgsign = true;
            tag.gpgsign = true;
            gpg.format = "ssh";
            alias = {
              co = "checkout";
              ci = "commit";
              st = "status";
              br = "branch";
              lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            };
            user = { inherit (config.dot.host.user) email name; };
          };
        };

        programs.lazygit = {
          enable = true;
          enableFishIntegration = true;
          settings.git.paging.pager = "${lib.getExe pkgs.delta} --paging=never";
        };

        dot = self.lib.mkIfHmPersistence config {
          hm.system.persistence.files = [ ".config/git/ignore" ];
        };
      };
  };
}
