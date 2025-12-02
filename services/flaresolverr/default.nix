{ config, lib, ... }:
let
  cfg = config.dot.services.flaresolverr;
in
{
  options.dot.services.flaresolverr = {
    enable = lib.mkEnableOption "Enable FlareSolverr service";
  };

  config = lib.mkIf cfg.enable {
    services.flaresolverr.enable = true;
  };
}
