{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.productivity = {
    imports = with modules; [
      betterbird
      browsers
    ];
  };
}
