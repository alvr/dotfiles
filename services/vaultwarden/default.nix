{ config, lib, ... }:
let
  cfg = config.dot.services.vaultwarden;
in
{
  options.dot.services.vaultwarden = {
    enable = lib.mkEnableOption "Enable Vaultwarden service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        environmentFile = config.sops.secrets.vaultwarden.path;
      };

      nginx.virtualHosts."vault.alvr.dev" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:8222";
          proxyWebsockets = true;
        };
      };
    };

    dot = {
      services.cloudflared.ingress = [ "vault.alvr.dev" ];
      services.postgresql.databases = [ "vaultwarden" ];

      system.persistence.directories = [
        {
          directory = "/var/lib/vaultwarden";
          user = "vaultwarden";
          group = "vaultwarden";
          mode = "u=rwx,g=,o=";
        }
      ];
    };

    sops.secrets.vaultwarden = {
      format = "dotenv";
      sopsFile = ../../secrets/services/vaultwarden.env;
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
