{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.sonarr;
in
{
  options.dot.services.sonarr = {
    enable = lib.mkEnableOption "Enable Sonarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      sonarr = {
        enable = true;
        dataDir = "/var/lib/sonarr";
        package = pkgs.sonarr;
      };

      caddy.virtualHosts."sonarr.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:8989
      '';

      cloudflared.tunnels.apeiron.ingress."sonarr.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "sonarr.alvr.dev";
          originServerName = "sonarr.alvr.dev";
        };
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/sonarr";
        user = "sonarr";
        group = "sonarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/sonarr 0700 sonarr sonarr -"
    ];

    users.groups.media = { };
    users.users.sonarr.extraGroups = [ "media" ];
  };
}
