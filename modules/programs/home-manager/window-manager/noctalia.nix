{ inputs, ... }:
{
  flake.modules.homeManager.noctalia = {
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia = {
      enable = true;
      systemd.enable = true;

      settings = {
        backdrop.enabled = true;

        bar = {
          order = [ "Banner" ];

          Banner = {
            start = [
              "bar"
              "launcher"
              "wallpaper"
              "workspaces"
            ];
          };
        };

        calendar = {
          enabled = true;
          account.personal_google.type = "google";
        };

        control_center.sidebar = "full";

        dock = {
          active_monitor_only = true;
          enabled = true;
          reserve_space = false;
          show_dots = true;
          smart_auto_hide = true;
        };

        idle = {
          behavior_order = [
            "lock"
            "screen-off"
            "lock-and-suspend"
          ];

          behavior = {
            lock = {
              action = "lock";
              timeout = 300.0;
            };
            screen-off = {
              action = "screen_off";
              timeout = 330.0;
            };
            lock-and-suspend = {
              action = "lock_and_suspend";
              timeout = 600.0;
            };
          };
        };

        location.auto_locate = true;

        lockscreen_widgets = {
          enabled = true;
          widget_order = [
            "lockscreen-login-box@WL-1"
            "lockscreen-login-box@HDMI-A-1"
            "lockscreen-login-box@DP-3"
          ];
          widget = {
            "lockscreen-login-box@WL-1" = {
              type = "login_box";
              output = "WL-1";
              cx = 640.0;
              cy = 1204.0;
              box_width = 810.0;
              box_height = 196.0;
              placement_width = 1280.0;
              placement_height = 1386.0;
            };
            "lockscreen-login-box@HDMI-A-1" = {
              type = "login_box";
              output = "HDMI-A-1";
              cx = 960.0;
              cy = 898.0;
              box_width = 810.0;
              box_height = 196.0;
              placement_width = 1920.0;
              placement_height = 1080.0;
            };
            "lockscreen-login-box@DP-3" = {
              type = "login_box";
              output = "DP-3";
              cx = 1280.0;
              cy = 1258.0;
              box_width = 810.0;
              box_height = 196.0;
              placement_width = 2560.0;
              placement_height = 1440.0;
            };
          };
        };

        nightlight = {
          enabled = true;
          temperature_night = 4200;
        };

        plugin_settings."noctalia/umbriel-companion".panel_layer = "overlay";

        plugins.enabled = [
          "noctalia/bitwarden"
          "noctalia/umbriel-companion"
        ];

        shell = {
          font_family = "Iosevka Fixed SS14";
          umbriel_overview_type_to_launch_enabled = true;
          polkit_agent = true;
          screen_time_enabled = true;

          greeter_sync.auto_sync = true;

          launcher = {
            app_grid = true;
            compact = true;
          };

          screenshot = {
            annotate = true;
            confirm_region = true;
          };
        };

        theme = {
          mode = "dark";
          source = "wallpaper";
          wallpaper_scheme = "soft";

          builtin = "Catppuccin";
          community_palette = "Catppuccin Mocha Peach";

          templates = {
            builtin_ids = [
              "btop"
              "gtk3"
              "gtk4"
              "kcolorscheme"
              "kitty"
              "qt"
              "starship"
              "umbriel"
            ];
            community_ids = [
              "opencode"
              "spotifast"
              "brave-origin"
              "zen-browser"
              "discord"
              "zapfast"
              "neovim"
              "obsidian"
              "vscode"
              "zed"
              "steam"
              "vicinae"
              "thunderbird"
              "cosmic"
              "bat"
              "fzf"
              "lazygit"
              "yazi"
            ];
          };
        };

        # Random wallpaper on login and every 30 min (automation.interval_seconds
        # defaults to 1800, order defaults to random).
        wallpaper = {
          directory = "${inputs.wallpapers}";
          transition_on_startup = true;
          automation.enabled = true;
        };

        widget.bar.type = "noctalia/umbriel-companion:bar";
      };
    };
  };
}
