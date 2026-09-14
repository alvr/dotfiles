{
  flake.modules.homeManager.starship = { config, ... }: {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings.palette = "catppuccin_${config.catppuccin.flavor}";

      presets = [
        "catppuccin-powerline"
        "nerd-font-symbols"
      ];
    };
  };
}
