{ config, lib, ... }:
let
  cfg = config.dot.services.bazarr;

  subdomain = "bazarr";
  port = 6767;
in
{
  options.dot.services.bazarr = {
    enable = lib.mkEnableOption "Enable Bazarr service";
  };

  config = lib.mkIf cfg.enable {
    services.bazarr = {
      enable = true;
      listenPort = port;
    };

    dot.services = {
      cloudflared.subdomains = [ subdomain ];
      nginx.hosts = [
        {
          inherit subdomain port;
          config.locations."/".proxyWebsockets = true;
        }
      ];

      oauth2-proxy.hosts.${subdomain}.allowed_groups = [ "bazarr_users" ];
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/bazarr";
        user = "bazarr";
        group = "bazarr";
        mode = "u=rwx,g=,o=";
      }
    ];

    systemd.services.bazarr = {
      requires = [
        "nginx.service"
        "oauth2-proxy.service"
      ];
      after = [
        "nginx.service"
        "oauth2-proxy.service"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/bazarr 0700 bazarr bazarr -"
    ];

    users.groups.media = { };
    users.users.bazarr.extraGroups = [ "media" ];
  };
}
