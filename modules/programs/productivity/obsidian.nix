{ inputs, ... }:
{
  flake.modules = {
    nixos.obsidian = {
      nixpkgs.overlays = [ inputs.obsidian-extensions.overlays.default ];
    };

    darwin.obsidian = {
      nixpkgs.overlays = [ inputs.obsidian-extensions.overlays.default ];
    };

    homeManager.obsidian =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        documents = lib.removePrefix "${config.home.homeDirectory}/" (
          config.xdg.userDirs.documents or "${config.home.homeDirectory}/Documents"
        );
      in
      {
        programs.obsidian = {
          enable = true;

          vaults.personal = {
            target = "${documents}/Obsidian/Personal";

            settings = {
              app = {
                alwaysUpdateLinks = true;
                attachmentFolderPath = "Adjuntos";
                newFileLocation = "folder";
                newFileFolderPath = "Inbox";
                showLineNumber = true;
                spellcheck = true;
                strictLineBreaks = false;
                useMarkdownLinks = false;
              };

              corePlugins = [
                "backlink"
                "bookmarks"
                "canvas"
                "command-palette"
                "editor-status"
                "file-explorer"
                "file-recovery"
                "global-search"
                "graph"
                "note-composer"
                "outgoing-link"
                "outline"
                "page-preview"
                "properties"
                "switcher"
                "tag-pane"
                "word-count"
                {
                  name = "daily-notes";
                  settings = {
                    folder = "Daily";
                    format = "YYYY-MM-DD";
                  };
                }
                {
                  name = "templates";
                  settings.folder = "Plantillas";
                }
              ];

              communityPlugins = [
                {
                  pkg = pkgs.obsidianPlugins.obsidian-excalidraw-plugin;
                  enable = true;
                  settings = {
                    folder = "Excalidraw";
                    compress = true;
                    matchTheme = true;
                  };
                }
                {
                  pkg = pkgs.obsidianPlugins.obsidian-icon-folder;
                  enable = true;
                }
                {
                  pkg = pkgs.obsidianPlugins.obsidian-livesync;
                  enable = true;
                }
                {
                  pkg = pkgs.obsidianPlugins.obsidian-wakatime;
                  enable = true;
                }
                {
                  pkg = pkgs.obsidianPlugins.omnisearch;
                  enable = true;
                  settings = {
                    showExcerpt = true;
                    highlight = true;
                    ignoreDiacritics = true;
                    ribbonIcon = true;
                    maxEmbeds = 5;
                  };
                }
              ];
            };
          };
        };
      };
  };
}
