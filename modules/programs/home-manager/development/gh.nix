{
  flake.modules.homeManager.gh = { config, pkgs, ... }: {
    programs.gh = {
      enable = true;

      extensions = with pkgs; [
        gh-dash
        gh-poi
        gh-stack
      ];

      hosts = {
        "github.com" = {
          git_protocol = "ssh";
          user = config.home.username;
        };
      };

      settings = {
        git_protocol = "https";
        prompt = "enabled";
        spinner = "enabled";

        aliases = {
          co = "pr checkout";
          pv = "pr view";
        };
      };
    };
  };
}
