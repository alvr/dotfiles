{ inputs, ... }:
{
  flake.modules.nixos.papra =
    { config, ... }:
    let
      subdomain = "papers";
      port = 12212;
    in
    {
      services.papra = {
        enable = true;
        environmentFiles = [ config.sops.secrets."papra/env".path ];
        environment = {
          APP_BASE_URL = "https://${subdomain}.${config.dot.host.network.domain}";
          DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/data/papra/documents";
          INGESTION_FOLDER_ROOT_PATH = "/data/papra/ingestion";
          PORT = port;
        };
      };

      dot.services = {
        restic.include = [ "/data/papra" ];
        nginx.hosts = [
          {
            inherit subdomain port;
            internal = true;
          }
        ];
      };

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/papra";
          user = "papra";
          group = "papra";
          mode = "u=rwx,g=,o=";
        }
      ];

      sops.secrets."papra/env" = {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/papra.yaml";
        owner = "papra";
        group = "papra";
        mode = "0400";
        restartUnits = [ "papra.service" ];
      };

      systemd.services.papra = {
        requires = [
          "nginx.service"
          "pocket-id.service"
        ];
        after = [
          "nginx.service"
          "pocket-id.service"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/papra 0700 papra papra -"
      ];
    };
}
