{ config, lib, ... }:
let
  cfg = config.dot.services.linkwarden;

  subdomain = "links";
  port = 4103;
in
{
  options.dot.services.linkwarden = {
    enable = lib.mkEnableOption "Enable Linkwarden service";
  };

  config = lib.mkIf cfg.enable {
    services.linkwarden = {
      enable = true;
      environmentFile = config.sops.secrets.linkwarden.path;
      inherit port;
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      postgresql.databases = [ "linkwarden" ];
      nginx.hosts = [
        { inherit subdomain port; }
      ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/linkwarden";
        user = "linkwarden";
        group = "linkwarden";
        mode = "u=rwx,g=,o=";
      }
    ];

    sops.secrets.linkwarden = {
      format = "dotenv";
      sopsFile = ../../secrets/services/linkwarden.env;
      owner = "linkwarden";
      group = "linkwarden";
      mode = "0400";
      restartUnits = [ "linkwarden.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/linkwarden 0700 linkwarden linkwarden -"
    ];
  };
}
