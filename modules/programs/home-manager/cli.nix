{ config, ... }:
let
  modules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.cli = {
    imports = with modules; [
      bat
      btop
      delta
      eza
      fd
      fish
      fzf
      ripgrep
      yazi
      zoxide
    ];
  };
}
