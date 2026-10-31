{ inputs, ... }:
{
  flake.modules.homeManager.umbriel = {
    imports = [ inputs.umbriel.homeModules.default ];

    programs.umbriel = {
      enable = true;

      settings = {
        include.optional.files = [ "noctalia.toml" ];

        input = {
          mouse = {
            accel_profile = "flat";
            sensitivity = -0.175;
          };

          keyboard = {
            layout = "es";
            options = "lv3:rwin_switch";
          };
        };

        appearance = {
          prefer_no_csd = true;
          border_width = 2;
          corner_radius = 10;

          blur = {
            enabled = true;
            optimized = true;
            passes = 3;
            radius = 3;
            noise = 0.02;
            brightness = 0.9;
            contrast = 0.9;
            saturation = 1.1;
          };
        };

        layout.extent_presets = [
          0.25
          0.333
          0.5
          0.667
          1.0
        ];

        window_rule = [
          {
            blur = true;
            blur_optimized = true;
          }
          {
            match.app_id = "^dev.noctalia.Noctalia$";
            default_floating = true;
            default_floating_size_px = {
              width = 1020;
              height = 900;
            };
          }
          {
            match.app_id = "^scratch-terminal$";
            default_scratchpad = "terminal";
            default_focused = true;
          }
          {
            match.app_id = [
              "^zen"
              "^helium"
              "^brave-browser$"
            ];
            default_output = "HDMI-A-1";
            default_workspace = "Browsing";
            default_maximize = true;
          }
          {
            match.app_id = [
              "^dev.zed.Zed"
              "^jetbrains-studio$"
            ];
            default_output = "DP-3";
            default_workspace = "Develop";
            default_maximize = true;
          }
          {
            match.app_id = [
              "^[Ss]team$"
              "^com.valvesoftware.Steam$"
            ];
            default_output = "DP-3";
            default_workspace = "Gaming";
            default_scrolling_extent = 0.5;
          }
          {
            match.app_id = [
              "^[Ss]potify$"
              "^com.spotify.Client$"
            ];
            default_output = "HDMI-A-1";
            default_workspace = "Music";
            default_scrolling_extent = 0.5;
          }
          {
            match.app_id = [
              "^zapfast$"
              "^equibop$"
            ];
            default_output = "HDMI-A-1";
            default_workspace = "Messaging";
          }
        ];

        scratchpad = [
          {
            name = "terminal";
            spawn_when_empty = "kitty --class scratch-terminal";
          }
        ];

        layer_rule = [
          {
            match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
            blur = true;
            blur_ignore_alpha = 0.5;
            blur_optimized = false;
          }
        ];

        hot_corners.top_left = {
          enabled = true;
          action = "overview-toggle";
        };

        keybinds = {
          # Apps and Noctalia
          "Mod+Space" = "spawn noctalia msg panel-toggle launcher";
          "Mod+S" = "spawn noctalia msg panel-toggle control-center";
          "Mod+Comma" = "spawn noctalia msg settings-toggle";
          "Alt+Tab" = "spawn noctalia msg window-switcher hold";

          # Screenshots
          "Mod+Shift+A" = "spawn noctalia msg screenshot-annotate";
          "Mod+Ctrl+A" = "spawn noctalia msg annotate";
          "Print" = "spawn noctalia msg screenshot-region";

          # Hardware and media keys
          "XF86MonBrightnessDown" = "spawn noctalia msg brightness-down";
          "XF86MonBrightnessUp" = "spawn noctalia msg brightness-up";
          "XF86Calculator" = "spawn kcalc";
          "XF86LaunchA" = "overview-toggle";
          "XF86AudioPrev" = "spawn noctalia msg media previous";
          "XF86AudioPlay" = "spawn noctalia msg media toggle";
          "XF86AudioPause" = "spawn noctalia msg media toggle";
          "XF86AudioMedia" = "spawn noctalia msg media toggle";
          "XF86AudioStop" = "spawn noctalia msg media stop";
          "XF86AudioNext" = "spawn noctalia msg media next";
          "XF86AudioMute" = "spawn noctalia msg volume-mute";
          "XF86AudioLowerVolume" = "spawn noctalia msg volume-down";
          "XF86AudioRaiseVolume" = "spawn noctalia msg volume-up";

          # Window actions
          "Mod+Return" = {
            action = "spawn kitty";
            repeat = false;
          };
          "Mod+Q" = "window-close";
          "Mod+Shift+Q" = {
            action = "window-kill";
            repeat = false;
          };
          "Mod+Shift+Space" = "window-toggle-floating";
          "Mod+F11" = {
            action = "window-toggle-fullscreen";
            repeat = false;
          };

          # Focus
          "Mod+Left" = "window-focus-left";
          "Mod+Right" = "window-focus-right";
          "Mod+Up" = "window-focus-up";
          "Mod+Down" = "window-focus-down";
          "Mod+Ctrl+Left" = "output-focus-left";
          "Mod+Ctrl+Right" = "output-focus-right";

          # Move windows
          "Mod+Shift+Left" = "window-move-left";
          "Mod+Shift+Right" = "window-move-right";
          "Mod+Shift+Up" = "window-move-up";
          "Mod+Shift+Down" = "window-move-down";
          "Mod+Shift+Ctrl+Left" = "window-move-to-output-left";
          "Mod+Shift+Ctrl+Right" = "window-move-to-output-right";

          # Layout and sizing
          # Cycle the focused workspace's layout: scrolling -> dwindle -> master.
          # Each workspace remembers its own layout.
          "Mod+Shift+L" = {
            action = "workspace-set-layout toggle";
            repeat = false;
          };

          # Enter resize mode; bare arrows resize while held, Escape exits.
          # See layout.extent_presets for exact-fraction jumps instead.
          "Mod+R" = {
            action = "submap resize";
            repeat = false;
          };
          "submap[resize],Left" = "window-modify-width-left -0.05";
          "submap[resize],Right" = "window-modify-width-right 0.05";
          "submap[resize],Up" = "window-modify-height-up -0.05";
          "submap[resize],Down" = "window-modify-height-down 0.05";
          "submap[resize],Escape" = "submap reset";

          # Exact sizes: quarter, third, half, two-thirds, three-quarters, full.
          "Mod+F" = {
            action = "submap sizes";
            repeat = false;
          };
          "submap[sizes],1" = "window-set-primary-extent 0.25";
          "submap[sizes],2" = "window-set-primary-extent 0.333";
          "submap[sizes],3" = "window-set-primary-extent 0.5";
          "submap[sizes],4" = "window-set-primary-extent 0.667";
          "submap[sizes],5" = "window-set-primary-extent 0.75";
          "submap[sizes],6" = "window-set-primary-extent 1.0";
          "submap[sizes],Escape" = "submap reset";

          # Workspaces
          # Switch to the next/previous workspace on the focused output.
          "Mod+Page_Down" = "workspace-next";
          "Mod+Page_Up" = "workspace-previous";
          "Mod+Ctrl+Down" = "window-move-to-workspace-next";
          "Mod+Ctrl+Up" = "window-move-to-workspace-previous";
          "Mod+WheelLeft" = "window-focus-left";
          "Mod+WheelRight" = "window-focus-right";
          "Mod+WheelUp" = {
            action = "workspace-previous";
            cooldown_ms = 150;
          };
          "Mod+WheelDown" = {
            action = "workspace-next";
            cooldown_ms = 150;
          };

          # Jump to a workspace by its 1-based position on the focused
          # output (Browsing/Music/Other on HDMI-A-1, Develop/Gaming/Misc
          # on DP-3; 4-9 target further, dynamically-created workspaces).
          "Mod+1" = "workspace-switch 1";
          "Mod+2" = "workspace-switch 2";
          "Mod+3" = "workspace-switch 3";
          "Mod+4" = "workspace-switch 4";
          "Mod+5" = "workspace-switch 5";
          "Mod+6" = "workspace-switch 6";
          "Mod+7" = "workspace-switch 7";
          "Mod+8" = "workspace-switch 8";
          "Mod+9" = "workspace-switch 9";
          "Mod+Shift+1" = "window-move-to-workspace 1";
          "Mod+Shift+2" = "window-move-to-workspace 2";
          "Mod+Shift+3" = "window-move-to-workspace 3";
          "Mod+Shift+4" = "window-move-to-workspace 4";
          "Mod+Shift+5" = "window-move-to-workspace 5";
          "Mod+Shift+6" = "window-move-to-workspace 6";
          "Mod+Shift+7" = "window-move-to-workspace 7";
          "Mod+Shift+8" = "window-move-to-workspace 8";
          "Mod+Shift+9" = "window-move-to-workspace 9";

          # Scratchpad
          # Named scratchpad terminal: hide/show a kitty instance.
          "Mod+Backspace" = "scratchpad-toggle terminal";

          # Session and system
          "Mod+Ctrl+Escape" = {
            action = "spawn systemctl suspend";
            repeat = false;
          };

          # Let a game/remote-desktop client receive its own shortcuts;
          # press again to restore normal bindings.
          "Mod+Shift+Backspace" = {
            action = "shortcuts-inhibit-toggle";
            allow_when_inhibited = true;
            repeat = false;
          };
          # Keybind cheatsheet.
          # masculine is the es-layout keysym for the º key.
          "Mod+masculine" = "cheatsheet-toggle";
        };

        output = {
          "HDMI-A-1" = {
            mode = "1920x1080@60";
            workspaces = "dynamic";
            min_workspaces = 3;
            position = [
              0
              360
            ];
          };

          "DP-3" = {
            mode = "2560x1440@180";
            vrr = "always";
            hdr = "on";
            workspaces = "dynamic";
            min_workspaces = 3;
            position = [
              1920
              0
            ];
            focus_at_startup = true;
          };
        };

        workspace = [
          {
            name = "Browsing";
            output = "HDMI-A-1";
          }
          {
            name = "Music";
            output = "HDMI-A-1";
          }
          {
            name = "Messaging";
            output = "HDMI-A-1";
          }
          {
            name = "Develop";
            output = "DP-3";
          }
          {
            name = "Gaming";
            output = "DP-3";
          }
          {
            name = "Other";
            output = "DP-3";
          }
        ];
      };
    };
  };
}
