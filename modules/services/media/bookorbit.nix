{ inputs, ... }:
{
  flake.modules.nixos.bookorbit =
    { config, ... }:
    let
      subdomain = "books-v2";
      port = 6061;
    in
    {
      services.bookorbit = {
        enable = true;
        createDatabaseLocally = true;
        environmentFile = config.sops.secrets."bookorbit/env".path;
        environment = {
          APP_URL = "https://${subdomain}.${config.dot.host.network.domain}";
          DISABLE_LOCAL_AUTH = "true";
          LIBRARY_BROWSE_ROOT = "/data/books";
          PORT = port;
        };
      };

      dot.services = {
        cloudflared.subdomains = [ subdomain ];
        nginx.hosts = [
          {
            inherit subdomain port;
          }
        ];
        restic.include = [ "/data/books" ];
      };

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/bookorbit";
          user = "bookorbit";
          group = "bookorbit";
          mode = "u=rwx,g=,o=";
        }
      ];

      sops.secrets."bookorbit/env" = {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/bookorbit.yaml";
        owner = "bookorbit";
        group = "bookorbit";
        mode = "0400";
        restartUnits = [ "bookorbit.service" ];
      };
    };
}
