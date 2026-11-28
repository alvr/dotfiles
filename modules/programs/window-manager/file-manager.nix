{ inputs, ... }:
{
  flake.modules = {
    nixos.file-manager = { lib, pkgs, ... }: {
      imports = [ inputs.luciole.nixosModules.default ];

      nix.settings = {
        extra-substituters = [ "https://noctalia.cachix.org" ];
        extra-trusted-public-keys = [
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };

      programs.luciole.enable = true;
      services.gvfs.enable = true;

      xdg.portal = {
        enable = lib.mkDefault true;
        extraPortals = [ inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      };
    };

    homeManager.file-manager = { lib, pkgs, ... }: {
      imports = [ inputs.luciole.homeModules.default ];

      home.packages = [ pkgs.photoqt ];

      programs.luciole = {
        enable = true;

        settings.browser = {
          view_mode = "grid";
          terminal_command = lib.getExe pkgs.ghostty;
        };
      };

      xdg.mimeApps.defaultApplications = {
        "image/*" = "org.photoqt.PhotoQt.desktop";
        "inode/directory" = "dev.noctalia.luciole.desktop";
      };
    };
  };
}
