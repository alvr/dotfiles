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

      # Programs
      btop
      direnv
      eza
      fish
      git
      yazi
      zoxide
    ];
  };
}
