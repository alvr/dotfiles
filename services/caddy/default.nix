{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.caddy;
in
{
  options.dot.services.caddy = {
    enable = lib.mkEnableOption "Enable Caddy service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      tailscale.permitCertUid = "caddy";

      caddy = {
        enable = true;
        environmentFile = config.sops.secrets.caddy.path;
        email = "alvaro@alvr.dev";

        package = pkgs.unstable.caddy.withPlugins {
          hash = "sha256-DQMdKd/mtvgTPlpzVztsMf3Lo0i2DnVqVPCfdwTcyik=";
          plugins = [
            "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
            "github.com/caddy-dns/cloudflare@v0.2.2-0.20250724223520-f589a18c0f5d"
          ];
        };

        globalConfig = ''
          admin unix/${config.services.caddy.dataDir}/admin.sock

          servers {
            client_ip_headers CF-Connecting-IP
            trusted_proxies static 127.0.0.1 ::1 localhost
            trusted_proxies cloudflare {
              interval 24h
              timeout 60s
            }
          }
        '';

        extraConfig = ''
          (common) {
            encode zstd gzip
            
            header {
              Referrer-Policy "strict-origin-when-cross-origin"
              Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
              X-Content-Type-Options "nosniff"
              X-Frame-Options "DENY"
              X-Client-IP {http.request.header.CF-Connecting-IP}
              X-XSS-Protection "1; mode=block"
              -Last-Modified
              -Server
              -X-Powered-By
            }

            tls { 
              dns cloudflare {env.CF_API_TOKEN} 
            }
          }
        '';
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/caddy";
        user = "caddy";
        group = "caddy";
        mode = "u=rwx,g=,o=";
      }
    ];

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
    };

    sops.secrets.caddy = {
      format = "dotenv";
      sopsFile = ../../secrets/services/caddy.env;
      owner = "caddy";
      group = "caddy";
      mode = "0400";
      restartUnits = [ "caddy.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/caddy 0700 caddy caddy -"
    ];
  };
}
