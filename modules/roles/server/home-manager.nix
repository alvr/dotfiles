{ config, ... }:
let
  modules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.server = {
    imports = with modules; [
      base

      # Features
      sops
      impermanence

      # Programs - CLI
      bat
      btop
      eza
      fish
      yazi
      zoxide

      # Programs - Development
      direnv
      git
    ];
  };
}
