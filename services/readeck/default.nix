{ config, lib, ... }:
let
  cfg = config.dot.services.readeck;

  subdomain = "links";
  port = 4103;
in
{
  options.dot.services.readeck = {
    enable = lib.mkEnableOption "Enable Readeck service";
  };

  config = lib.mkIf cfg.enable {
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
      sopsFile = ../../secrets/services/readeck.yaml;
      mode = "0400";
      restartUnits = [ "readeck.service" ];
    };
  };
}
