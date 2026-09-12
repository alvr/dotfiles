{
  flake.modules.homeManager.starship = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      presets = [
        "catppuccin-powerline"
        "nerd-font-symbols"
      ];
    };
  };
}
