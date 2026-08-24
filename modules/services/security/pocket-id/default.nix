{ inputs, ... }:
{
  flake.modules.nixos.pocket-id =
    { config, ... }:
    let
      subdomain = "id";
      port = 1411;
    in
    {
      services.pocket-id = {
        enable = true;
        environmentFile = config.sops.secrets."pocket-id/env".path;

        settings = {
          APP_URL = "https://${subdomain}.${config.dot.host.network.domain}";
          PORT = port;
          TRUST_PROXY = true;
        };
      };

      dot.services = {
        cloudflared.subdomains = [ subdomain ];
        postgresql.databases = [ "pocket-id" ];
        nginx.hosts = [
          { inherit subdomain port; }
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
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/pocket-id.yaml";
        owner = "pocket-id";
        group = "pocket-id";
        mode = "0400";
        restartUnits = [ "pocket-id.service" ];
      };

      systemd.services.pocket-id = {
        requires = [
          "nginx.service"
          "cloudflared-tunnel-${config.dot.host.name}.service"
        ];
        after = [
          "nginx.service"
          "cloudflared-tunnel-${config.dot.host.name}.service"
        ];
        serviceConfig = {
          RestartMaxDelaySec = "1min";
          RestartSteps = 5;
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/pocket-id 0700 pocket-id pocket-id -"
      ];
    };
}
