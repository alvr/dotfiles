{
  flake.modules.homeManager.kitty = {
    catppuccin.kitty.enable = true;

    programs.kitty = {
      enable = true;
      settings = {
        font_family = "Maple Mono NF";
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
        background_opacity = "0.75";
        background_blur = 32;
        initial_window_width = 600;
        initial_window_height = 468;
      };
    };
  };
}
