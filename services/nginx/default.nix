{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.nginx;

  realIPFrom = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
  fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
  cfIPv4 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v4";
      sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
    }
  );
  cfIPv6 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v6";
      sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
    }
  );
in
{
  options.dot.services.nginx = {
    enable = lib.mkEnableOption "Enable Nginx service";
  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx = {
        enable = true;
        package = pkgs.nginxMainline;
        recommendedBrotliSettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        commonHttpConfig = ''
          ${realIPFrom cfIPv4}
          ${realIPFrom cfIPv6}

          set_real_ip_from 127.0.0.1;
          set_real_ip_from ::1;

          real_ip_header CF-Connecting-IP;
          real_ip_recursive on;
        '';

        appendHttpConfig = ''
          map $http_cf_connecting_ip $client_real_ip {
            default $http_cf_connecting_ip;
            "" $remote_addr;
          }

          add_header Referrer-Policy "strict-origin-when-cross-origin" always;
          add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-Frame-Options "DENY" always;
          add_header X-XSS-Protection "1; mode=block" always;

          more_clear_headers 'Server';
          more_clear_headers 'X-Powered-By';
          more_clear_headers 'Last-Modified';
        '';

        tailscaleAuth = {
          enable = true;
          expectedTailnet = "dachshund-roach.ts.net";
        };
      };

      tailscale.permitCertUid = "nginx";
    };

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
    };

    security.acme = {
      acceptTerms = true;

      defaults = {
        credentialsFile = config.sops.secrets.acme.path;
        dnsProvider = "cloudflare";
        email = "alvaro@alvr.dev";
      };
    };

    sops.secrets.acme = {
      format = "dotenv";
      sopsFile = ../../secrets/services/acme.env;
      owner = "acme";
      group = "acme";
      mode = "0400";
    };

    users.users.nginx.extraGroups = [ "acme" ];
  };
}
