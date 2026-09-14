{ config, ... }:
let
  modules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.development = {
    imports = with modules; [
      direnv
      gh
      git
      lazygit
      nvchad
    ];
  };
}
