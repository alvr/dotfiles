{ inputs, ... }:
{
  flake.modules = {
    nixos.x-craft = {
      imports = [ inputs.omniflake.flakes.nix-craftapps.nixosModules.default ];
    };

    homeManager.x-craft = {
      imports = [ inputs.omniflake.flakes.nix-craftapps.homeManagerModules.default ];

      programs.craftapps = {
        enable = true;

        apps = {
          deckcraft.enable = true;
          filmcraft.enable = true;
          gridcraft.enable = true;
          pdfcraft.enable = true;
          photocraft.enable = true;
          vectorcraft.enable = true;
          wordcraft.enable = true;
        };
      };

      xdg.mimeApps.defaultApplications = {
        "application/pdf" = "ai.storyteller.pdfcraft.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "ai.storyteller.deckcraft.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
          "ai.storyteller.gridcraft.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "ai.storyteller.wordcraft.desktop";
      };
    };

    darwin.x-craft = {
      imports = [ inputs.omniflake.flakes.nix-craftapps.darwinModules.default ];
    };
  };
}
