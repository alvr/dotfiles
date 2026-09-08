{ config, ... }:
let
  modules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.desktop = {
    imports = with modules; [
      base

      # Features
      sops

      # Programs
      btop
      direnv
      eza
      fish
      git
      nvchad
      starship
      yazi
      zoxide
    ];
  };
}
