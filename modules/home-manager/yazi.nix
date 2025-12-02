{ config, lib, ... }:
let
  cfg = config.dot.hm.programs.yazi;
in
{
  options.dot.hm.programs.yazi = {
    enable = lib.mkEnableOption "Enable yazi home-manager program";
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
