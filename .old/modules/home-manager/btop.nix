{ config, lib, ... }:
let
  cfg = config.dot.hm.programs.btop;
in
{
  options.dot.hm.programs.btop = {
    enable = lib.mkEnableOption "Enable btop home-manager program";
  };

  config = lib.mkIf cfg.enable {
    programs.btop.enable = true;
  };
}
