{ inputs, ... }:
{
  flake.modules.nixos.readeck =
    { config, ... }:
    let
      subdomain = "links";
      port = 4103;
    in
    {
      services.readeck = {
        enable = true;
        environmentFile = config.sops.secrets."readeck/env".path;
        settings.server.port = port;
      };

      dot.services = {
        cloudflared.subdomains = [ subdomain ];
        postgresql.databases = [ "readeck" ];
        nginx.hosts = [
          { inherit subdomain port; }
        ];
      };

      dot.system.persistence.directories = [
        "/var/lib/private/readeck"
      ];

      sops.secrets."readeck/env" = {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/readeck.yaml";
        owner = "readeck";
        group = "readeck";
        mode = "0400";
        restartUnits = [ "readeck.service" ];
      };

      systemd.services.readeck = {
        requires = [
          "nginx.service"
          "pocket-id.service"
        ];
        after = [
          "nginx.service"
          "pocket-id.service"
        ];
      };
    };
}
