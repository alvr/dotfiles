{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.vaultwarden;
in
{
  options.dot.services.vaultwarden = {
    enable = lib.mkEnableOption "Enable Vaultwarden service" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      environmentFile = config.sops.secrets.vaultwarden.path;
      package = pkgs.unstable.vaultwarden;
      webVaultPackage = pkgs.unstable.vaultwarden.webvault;
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/vaultwarden";
        user = "vaultwarden";
        group = "vaultwarden";
        mode = "u=rwx,g=,o=";
      }
    ];

    services.cloudflared.tunnels.apeiron.ingress."vault.alvr.dev" = {
      service = "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      originRequest = {
        originServerName = "vault.alvr.dev";
      };
    };

    sops.secrets.vaultwarden = {
      format = "dotenv";
      sopsFile = ../secrets/services/vaultwarden.env;
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
      restartUnits = [ "vaultwarden.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/vaultwarden 0700 vaultwarden vaultwarden -"
    ];
  };
}
