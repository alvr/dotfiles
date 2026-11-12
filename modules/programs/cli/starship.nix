{
  flake.modules.homeManager.starship = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;

      presets = [
        "nerd-font-symbols"
      ];
    };
  };
}
