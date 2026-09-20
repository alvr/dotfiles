{
  flake.modules.homeManager.lazygit = {
    programs.lazygit = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
