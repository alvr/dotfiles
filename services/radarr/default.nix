{ config, lib, ... }:
let
  cfg = config.dot.services.radarr;
in
{
  options.dot.services.radarr = {
    enable = lib.mkEnableOption "Enable Radarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      radarr = {
        enable = true;
        dataDir = "/var/lib/radarr";
      };

      caddy.virtualHosts."radarr.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:7878
      '';

      cloudflared.tunnels.apeiron.ingress."radarr.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "radarr.alvr.dev";
          originServerName = "radarr.alvr.dev";
        };
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/radarr";
        user = "radarr";
        group = "radarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/radarr 0700 radarr radarr -"
    ];

    users.groups.media = { };
    users.users.radarr.extraGroups = [ "media" ];
  };
}
