{
  flake.modules.nixos.seerr =
    { ... }:
    let
      subdomain = "seerr";
      port = 5055;
    in
    {
      services.seerr = {
        enable = true;
        inherit port;
      };

      dot = {
        services.cloudflared.subdomains = [ subdomain ];
        services.nginx.hosts = [
          { inherit subdomain port; }
        ];

        system.persistence.directories = [
          "/var/lib/private/jellyseerr"
        ];
      };

      systemd.services.seerr = {
        requires = [ "nginx.service" ];
        after = [ "nginx.service" ];
      };
    };
}
