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
      adminCredentialsFile = config.sops.secrets.miniflux.path;
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

    sops.secrets.miniflux = {
      format = "dotenv";
      sopsFile = ../../secrets/services/miniflux.env;
      group = "miniflux-secrets";
      mode = "0400";
    };

    systemd.services.miniflux.serviceConfig.SupplementaryGroups = [ "miniflux-secrets" ];
  };
}
