{ config, lib, ... }:
let
  cfg = config.dot.services.miniflux;
in
{
  options.dot.services.miniflux = {
    enable = lib.mkEnableOption "Enable Miniflux service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      miniflux = {
        enable = true;
        adminCredentialsFile = config.sops.secrets.miniflux.path;

        config = {
          BASE_URL = "https://rss.alvr.dev";
          LISTEN_ADDR = "localhost:9564";
        };
      };

      caddy.virtualHosts."rss.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:9564
      '';

      cloudflared.tunnels.apeiron.ingress."rss.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "rss.alvr.dev";
          originServerName = "rss.alvr.dev";
        };
      };
    };

    dot.services.postgresql.databases = [ "miniflux" ];

    users.groups.miniflux-secrets = { };

    sops.secrets.miniflux = {
      format = "dotenv";
      sopsFile = ../../secrets/services/miniflux.env;
      group = "miniflux-secrets";
      mode = "0400";
    };

    systemd.services.miniflux.serviceConfig.SupplementaryGroups = [ "miniflux-secrets" ];
  };
}
