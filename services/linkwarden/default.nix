{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.linkwarden;
in
{
  options.dot.services.linkwarden = {
    enable = lib.mkEnableOption "Enable Linkwarden service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      linkwarden = {
        enable = true;
        environmentFile = config.sops.secrets.linkwarden.path;
        package = pkgs.linkwarden;
        port = 4103;
      };

      caddy.virtualHosts."links.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:4103
      '';

      cloudflared.tunnels.apeiron.ingress."links.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "links.alvr.dev";
          originServerName = "links.alvr.dev";
        };
      };
    };

    dot.services.postgresql.databases = [ "linkwarden" ];

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
