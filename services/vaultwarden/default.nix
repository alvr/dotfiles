{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.vaultwarden;

  subdomain = "vault";
  port = 8222;
in
{
  options.dot.services.vaultwarden = {
    enable = lib.mkEnableOption "Enable Vaultwarden service";
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      environmentFile = config.sops.secrets."vaultwarden/env".path;

      config = {
        DOMAIN = "https://${subdomain}.${consts.domain}";
        ROCKET_PORT = port;
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "vaultwarden" ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/".proxyWebsockets = true;
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/vaultwarden";
        user = "vaultwarden";
        group = "vaultwarden";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."vaultwarden/env" = {
      sopsFile = ../../secrets/services/vaultwarden.yaml;
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
