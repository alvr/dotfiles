{
  flake.modules.homeManager.yazi = {
    catppuccin.yazi.enable = true;

    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "y";
    };
  };
}
