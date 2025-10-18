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
    enable = lib.mkEnableOption "Enable Vaultwarden service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      vaultwarden = {
        enable = true;
        environmentFile = config.sops.secrets.vaultwarden.path;
        package = pkgs.unstable.vaultwarden;
        webVaultPackage = pkgs.unstable.vaultwarden.webvault;
      };

      cloudflared.tunnels.apeiron.ingress."vault.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "vault.alvr.dev";
          originServerName = "vault.alvr.dev";
        };
      };

      traefik.dynamicConfigOptions.http = {
        services.vaultwarden.loadBalancer.servers = [
          { url = "http://localhost:8222"; }
        ];

        routers.vaultwarden = {
          entryPoints = [ "websecure" ];
          middlewares = [ "secure-headers" ];
          rule = "Host(`vault.alvr.dev`)";
          service = "vaultwarden";
          tls.certResolver = "letsencrypt";
        };
      };
    };

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
