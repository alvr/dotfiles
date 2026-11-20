{ inputs, ... }:
{
  flake.modules = {
    nixos.theming =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        iosevkaVariant = pkgs.iosevka-bin.override { variant = "SS14"; };
        uiFont = config.stylix.fonts.sansSerif.name;
        monoFont = config.stylix.fonts.monospace.name;
        preferAlias =
          font: families:
          lib.genAttrs families (_: {
            prefer = [ font ];
          });
      in
      {
        imports = [ inputs.stylix.nixosModules.stylix ];

        stylix = {
          enable = true;
          autoEnable = lib.mkDefault false;
          polarity = "dark";
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

          fonts = {
            sansSerif = {
              package = iosevkaVariant;
              name = "Iosevka Fixed SS14";
            };
            serif = {
              package = iosevkaVariant;
              name = "Iosevka Fixed SS14";
            };
            monospace = {
              package = pkgs.maple-mono.NF;
              name = "Maple Mono NF";
            };
            emoji = {
              package = pkgs.noto-fonts-color-emoji;
              name = "Noto Color Emoji";
            };

            sizes.applications = 11;
          };

          cursor = {
            package = pkgs.bibata-cursors;
            name = "Bibata-Modern-Ice";
            size = 24;
          };

          targets.fontconfig.enable = true;
        };

        fonts = {
          packages = with pkgs; [
            iosevkaVariant
            maple-mono.NF
            maple-mono.opentype
            nerd-fonts.iosevka
            nerd-fonts.iosevka-term
            noto-fonts-color-emoji
          ];

          # Electron/Chromium apps ignore gtk-font-name, so map the families
          # from their CSS stacks onto the Stylix fonts. These aliases are
          # global, so they also affect web content using these family names.
          fontconfig.aliases =
            preferAlias uiFont [
              "Arial"
              "Cantarell"
              "Droid Sans"
              "Fira Sans"
              "Helvetica Neue"
              "Helvetica"
              "Inter"
              "Oxygen"
              "Roboto"
              "Segoe UI"
              "Source Sans Pro"
              "Ubuntu"
            ]
            // preferAlias monoFont [
              "Consolas"
              "Courier New"
              "Courier"
              "Menlo"
              "Monaco"
            ];
        };

        environment.systemPackages = [ pkgs.adw-gtk3 ];
        programs.dconf.enable = true;

        qt = {
          enable = true;
          platformTheme = "kde";
          style = "breeze";
        };
      };

    homeManager.theming =
      { config, ... }:
      let
        inherit (config.stylix.fonts) monospace sansSerif;
        size = config.stylix.fonts.sizes.applications;
        kdeFont = family: "${family.name},${toString size}";
      in
      {
        gtk = {
          enable = true;

          font = {
            inherit (sansSerif) name;
            inherit size;
          };
        };

        home.pointerCursor.gtk.enable = true;

        qt.kde.settings.General = {
          font = kdeFont sansSerif;
          fixed = kdeFont monospace;
          menuFont = kdeFont sansSerif;
          toolBarFont = kdeFont sansSerif;
          taskbarFont = kdeFont sansSerif;
          desktopFont = kdeFont sansSerif;
          smallestReadableFont = kdeFont sansSerif;
        };

        stylix.targets = {
          lazygit.enable = true;
          starship.enable = true;
        };
      };
  };
}
