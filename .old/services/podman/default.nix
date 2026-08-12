{ config, lib, ... }:
let
  cfg = config.dot.services.podman;
in
{
  options.dot.services.podman = {
    enable = lib.mkEnableOption "Enable Podman service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      oci-containers.backend = "podman";

      podman = {
        enable = true;
        autoPrune.enable = true;
        defaultNetwork.settings.dns_enabled = true;
        dockerCompat = true;
      };
    };
  };
}
