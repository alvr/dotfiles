{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.desktop = {
    imports = with modules; [
      base
      audio
      bluetooth
      printing
      sops
    ];
  };
}
