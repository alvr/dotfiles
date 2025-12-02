{ config, lib, ... }:
let
  cfg = config.dot.services.podman;
in
{
  options.dot.services.podman = {
    enable = lib.mkEnableOption "Enable Podman service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
    };
  };
}
