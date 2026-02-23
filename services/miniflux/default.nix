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
        { inherit subdomain port; }
      ];
    };

    users.groups.miniflux-secrets = { };

    sops.secrets."miniflux/env" = {
      sopsFile = ../../secrets/services/miniflux.yaml;
      group = "miniflux-secrets";
      mode = "0400";
      restartUnits = [ "miniflux.service" ];
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
  };
}
