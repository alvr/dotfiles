{
  flake.modules.homeManager.zed = {
    programs.zed-editor = {
      enable = true;

      extensions = [
        "just"
        "matte-black"
        "nix"
        "npm-package-json-checker"
        "oxc"
        "wakatime"
      ];

      userSettings = {
        diff_view_style = "split";
        cli_default_open_behavior = "existing_window";
        disable_ai = false;
        colorize_brackets = true;
        ui_font_family = "Iosevka Fixed SS14";
        buffer_font_family = "Maple Mono";
        ui_font_size = 15.0;
        buffer_font_size = 14.0;
        base_keymap = "JetBrains";
        autosave.after_delay.milliseconds = 1000;
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        theme.mode = "dark";
        project_panel.dock = "left";
        outline_panel.dock = "left";
        collaboration_panel.dock = "left";
        git_panel = {
          dock = "left";
          tree_view = true;
        };
        terminal = {
          font_family = "Maple Mono NF";
          font_weight = 200.0;
        };
      };
    };
  };
}
