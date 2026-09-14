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

      # Programs - CLI
      bat
      btop
      eza
      fish
      kitty
      starship
      yazi
      zoxide

      # Programs - Development
      direnv
      gh
      git
      lazygit
      nvchad
    ];
  };
}
