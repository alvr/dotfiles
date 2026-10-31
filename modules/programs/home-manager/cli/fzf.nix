{
  flake.modules.homeManager.fzf = {
    catppuccin.fzf.enable = true;

    programs.fzf = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
