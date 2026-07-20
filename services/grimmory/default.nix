{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.services.grimmory;

  subdomain = "books";
  port = 6060;
in
{
  options.dot.services.grimmory = {
    enable = lib.mkEnableOption "Enable Grimmory service";
  };

  config = lib.mkIf cfg.enable {
    services.grimmory = {
      enable = true;
      environmentFile = config.sops.secrets."grimmory/env".path;
      dataDir = "/var/lib/booklore";
      booksDir = "/data/booklore/books";
      bookdropDir = "/data/booklore/drops";
    };

    dot.services = {
      backup.include = [ "/data/booklore" ];
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
        mode = "u=rwx,g=rx,o=";
      }
    ];

    sops.secrets."grimmory/env" = {
      sopsFile = ../../secrets/services/grimmory.yaml;
      owner = "grimmory";
      group = "grimmory";
      mode = "0400";
      restartUnits = [ "grimmory.service" ];
    };

    systemd.services.grimmory = {
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
      "d /var/lib/booklore 0700 grimmory grimmory -"
      "d /data/booklore/books 0700 grimmory grimmory -"
      "d /data/booklore/drops 0700 grimmory grimmory -"
    ];

    users.users.grimmory.extraGroups = [ "media" ];
  };
}
