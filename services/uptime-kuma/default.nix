{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.services.uptime-kuma;

  subdomain = "up";
  port = 4573;
in
{
  options.dot.services.uptime-kuma = {
    enable = lib.mkEnableOption "Enable Uptime Kuma service";
  };

  config = lib.mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;

      settings = {
        UPTIME_KUMA_DB_TYPE = "sqlite";
        UPTIME_KUMA_PORT = toString port;
      };
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/".proxyWebsockets = true;
        }
      ];
    };

    dot.system.persistence.directories = [
      "/var/lib/private/uptime-kuma"
    ];

    systemd.services.uptime-kuma = {
      requires = [ "nginx.service" ];
      after = [ "nginx.service" ];
    };
  };
}
