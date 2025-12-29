{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.pocket-id;

  subdomain = "id";
  port = 1411;
in
{
  options.dot.services.pocket-id = {
    enable = lib.mkEnableOption "Enable Pocket ID service";
  };

  config = lib.mkIf cfg.enable {
    services.pocket-id = {
      enable = true;
      environmentFile = config.sops.secrets."pocket-id/env".path;

      settings = {
        APP_URL = "https://${subdomain}.${consts.domain}";
        PORT = port;
        TRUST_PROXY = true;
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "pocket-id" ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/".extraConfig = ''
            proxy_busy_buffers_size 512k;
            proxy_buffers           4 512k;
            proxy_buffer_size       256k;
          '';
        }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/pocket-id";
        user = "pocket-id";
        group = "pocket-id";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets."pocket-id/env" = {
      sopsFile = ../../secrets/services/pocket-id.yaml;
      owner = "pocket-id";
      group = "pocket-id";
      mode = "0400";
      restartUnits = [ "pocket-id.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/pocket-id 0700 pocket-id pocket-id -"
    ];
  };
}
