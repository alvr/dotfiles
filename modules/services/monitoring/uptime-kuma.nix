{
  flake.modules.nixos.uptime-kuma =
    let
      subdomain = "up";
      port = 4573;
    in
    {
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

    };
}
