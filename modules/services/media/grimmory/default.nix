{ inputs, ... }:
{
  flake.modules.nixos.grimmory =
    { config, ... }:
    let
      subdomain = "books";
      port = 6060;
    in
    {
      imports = [ ./_service.nix ];

      services.grimmory = {
        enable = true;
        environmentFile = config.sops.secrets."grimmory/env".path;
        dataDir = "/var/lib/booklore";
        booksDir = "/data/booklore/books";
        bookdropDir = "/data/booklore/drops";
      };

      dot.services = {
        restic.include = [ "/data/booklore" ];
        cloudflared.subdomains = [ subdomain ];
        nginx.hosts = [
          {
            inherit subdomain port;
          }
        ];
      };

      dot.system.persistence.directories = [
        {
          directory = "/var/lib/booklore";
          user = "grimmory";
          group = "grimmory";
          mode = "u=rwx,g=,o=";
        }
      ];

      sops.secrets."grimmory/env" = {
        sopsFile = "${inputs.secrets}/${config.dot.host.name}/services/grimmory.yaml";
        owner = "grimmory";
        group = "grimmory";
        mode = "0400";
        restartUnits = [ "grimmory.service" ];
      };

      systemd.tmpfiles.rules = [
        # Z: adjust the existing trees recursively so the bookorbit service
        # (grimmory/media groups) can read books and covers during migration.
        "Z /var/lib/booklore 0750 grimmory grimmory -"
        "Z /data/booklore/books 0770 grimmory media -"
      ];

      users.users.grimmory.extraGroups = [ "media" ];
    };
}
