{
  config,
  consts,
  lib,
  ...
}:
let
  cfg = config.dot.services.miniflux;

  subdomain = "rss";
  port = 9564;
in
{
  options.dot.services.miniflux = {
    enable = lib.mkEnableOption "Enable Miniflux service";
  };

  config = lib.mkIf cfg.enable {
    services.miniflux = {
      enable = true;
      adminCredentialsFile = config.sops.secrets."miniflux/env".path;
      config = {
        BASE_URL = "https://${subdomain}.${consts.domain}";
        LISTEN_ADDR = "localhost:${toString port}";
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "miniflux" ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/metrics".return = 403;
        }
      ];
      prometheus.scrape.miniflux = lib.mkIf config.dot.services.prometheus.enable {
        inherit port;
        basic_auth = {
          username = "prometheus";
          password_file = config.sops.secrets."miniflux/metrics-password".path;
        };
      };
    };

    sops.secrets = {
      "miniflux/env" = {
        sopsFile = ../../secrets/services/miniflux.yaml;
        group = "miniflux-secrets";
        mode = "0400";
        restartUnits = [ "miniflux.service" ];
      };

      "miniflux/metrics-password" = lib.mkIf config.dot.services.prometheus.enable {
        sopsFile = ../../secrets/services/miniflux.yaml;
        owner = "prometheus";
        group = "prometheus";
        mode = "0400";
        restartUnits = [ "prometheus.service" ];
      };
    };

    systemd.services.miniflux = {
      requires = [
        "nginx.service"
        "pocket-id.service"
      ];
      after = [
        "nginx.service"
        "pocket-id.service"
      ];
      serviceConfig.SupplementaryGroups = [ "miniflux-secrets" ];
    };

    users.groups.miniflux-secrets = { };
  };
}
