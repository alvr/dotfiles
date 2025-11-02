{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.prowlarr;
in
{
  options.dot.services.prowlarr = {
    enable = lib.mkEnableOption "Enable Prowlarr service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      prowlarr = {
        enable = true;
        package = pkgs.unstable.prowlarr;
      };

      caddy.virtualHosts."prowlarr.alvr.dev".extraConfig = ''
        import common
        reverse_proxy localhost:9696
      '';

      cloudflared.tunnels.apeiron.ingress."prowlarr.alvr.dev" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "prowlarr.alvr.dev";
          originServerName = "prowlarr.alvr.dev";
        };
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/prowlarr";
        user = "prowlarr";
        group = "prowlarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/prowlarr 0700 prowlarr prowlarr -"
    ];

    # Disable DynamicUser
    systemd.services.prowlarr.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "prowlarr";
      Group = lib.mkForce "prowlarr";
    };

    users.groups.prowlarr = { };
    users.users.prowlarr = {
      home = "/var/lib/prowlarr";
      group = "prowlarr";
      isSystemUser = true;
    };
  };
}
