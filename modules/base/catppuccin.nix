{ inputs, ... }:
let
  catppuccinConfig = {
    enable = true;
    autoEnable = true;
    flavor = "macchiato";
    accent = "peach";
  };

  cacheSettings = {
    extra-substituters = [ "https://catppuccin.cachix.org" ];
    extra-trusted-public-keys = [
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    ];
  };
in
{
  flake.modules = {
    nixos.catppuccin = {
      imports = [ inputs.catppuccin.nixosModules.catppuccin ];
      catppuccin = catppuccinConfig;
      nix.settings = cacheSettings;
    };

    darwin.catppuccin = {
      imports = [ inputs.catppuccin.darwinModules.catppuccin ];
      catppuccin = catppuccinConfig;
      nix.settings = cacheSettings;
    };

    homeManager.catppuccin = {
      imports = [ inputs.catppuccin.homeModules.catppuccin ];
      catppuccin = catppuccinConfig;
      nix.settings = cacheSettings;
    };
  };
}
