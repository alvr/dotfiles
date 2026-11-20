{
  flake.modules.homeManager.zed =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.zed-editor = {
        enable = true;

        extraPackages = with pkgs; [
          nil
          wakatime-cli
        ];

        extensions = [
          "just"
          "matte-black"
          "nix"
          "npm-package-json-checker"
          "oxc"
          "wakatime"
        ];

        userSettings = {
          lsp = {
            nil.binary.path = lib.getExe pkgs.nil;

            wakatime.binary = {
              path = lib.getExe pkgs.zed-wakatime-ls;
              arguments = [
                "--wakatime-cli"
                (lib.getExe pkgs.wakatime-cli)
              ];
            };
          };

          diff_view_style = "split";
          cli_default_open_behavior = "existing_window";
          disable_ai = false;
          colorize_brackets = true;
          ui_font_family = config.stylix.fonts.sansSerif.name;
          buffer_font_family = config.stylix.fonts.monospace.name;
          ui_font_size = 15.0;
          buffer_font_size = 14.0;
          base_keymap = "JetBrains";
          autosave.after_delay.milliseconds = 1000;
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          theme = {
            mode = "dark";
            dark = "Noctalia Dark";
            light = "Noctalia Light";
          };
          project_panel.dock = "left";
          outline_panel.dock = "left";
          collaboration_panel.dock = "left";
          git_panel = {
            dock = "left";
            tree_view = true;
          };
          terminal = {
            font_family = config.stylix.fonts.monospace.name;
            font_weight = 200.0;
          };
        };
      };
    };
}
