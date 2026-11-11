{
  flake.modules.homeManager.ghostty = {
    catppuccin.ghostty.enable = true;

    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      installBatSyntax = true;

      settings = {
        background-blur = 32;
        background-opacity = 0.75;

        font-family = "Maple Mono NF";
        font-family-bold = "auto";
        font-family-italic = "auto";
        font-family-bold-italic = "auto";
        font-size = 11;

        language = "es";

        window-padding-x = 0;
        window-padding-y = 0;
        window-width = 166;
        window-height = 69;
      };
    };
  };
}
