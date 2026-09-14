{ config, ... }:
let
  modules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.cli = {
    imports = with modules; [
      bat
      btop
      eza
      fish
      yazi
      zoxide
    ];
  };
}
