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

      caddy.virtualHosts."vault.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:8222
      '';

      cloudflared.tunnels.apeiron.ingress."vault.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "vault.alvr.dev";
          originServerName = "vault.alvr.dev";
        };
      };
    };

    dot.services.postgresql.databases = [ "vaultwarden" ];

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/vaultwarden";
        user = "vaultwarden";
        group = "vaultwarden";
        mode = "u=rwx,g=,o=";
      }
    ];

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
