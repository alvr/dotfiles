{
  flake.modules.homeManager.delta = {
    catppuccin.delta.enable = true;

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
  };
}
