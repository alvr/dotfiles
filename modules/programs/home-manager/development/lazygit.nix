{
  flake.modules.homeManager.lazygit = {
    catppuccin.lazygit.enable = true;

    programs.lazygit = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
