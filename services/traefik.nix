{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.traefik;
in
{
  options.dot.services.traefik = {
    enable = lib.mkEnableOption "Enable Traefik service" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.permitCertUid = "traefik";
    services.traefik = {
      enable = true;
      environmentFiles = [ config.sops.secrets.traefik.path ];
      package = pkgs.unstable.traefik;
      staticConfigOptions = {
        api = {
          dashboard = true;
          insecure = false;
        };

        certificatesResolvers = {
          letsencrypt.acme = {
            email = "alvaro@alvr.dev";
            storage = "/var/lib/traefik/cert.json";
            dnsChallenge = {
              provider = "cloudflare";
            };
          };
        };

        entryPoints = {
          web = {
            address = "0.0.0.0:80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };

          websecure = {
            address = "0.0.0.0:443";
            http.tls = {
              certResolver = "letsencrypt";
              domains = [
                {
                  main = "alvr.dev";
                  sans = [ "*.alvr.dev" ];
                }
              ];
            };
          };
        };

        global.sendAnonymousUsage = false;

        log = {
          level = "INFO";
          format = "common";
        };
      };
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/traefik";
        user = "traefik";
        group = "traefik";
        mode = "u=rwx,g=,o=";
      }
    ];

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    sops.secrets.traefik = {
      format = "dotenv";
      sopsFile = ../secrets/services/traefik.env;
      owner = "traefik";
      group = "traefik";
      mode = "0400";
      restartUnits = [ "traefik.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/traefik 0700 traefik traefik -"
      "f /var/lib/traefik/cert.json 0600 traefik traefik -"
    ];
  };
}
