{
  config,
  consts,
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

    hosts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            config = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
            };
            subdomain = lib.mkOption {
              type = lib.types.str;
            };
            port = lib.mkOption {
              type = lib.types.port;
            };
          };
        }
      );
      default = [ ];
    };
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

          proxy_buffers           4 512k;
          proxy_buffer_size       1024k;
          proxy_busy_buffers_size 1024k;
        '';

        appendHttpConfig = ''
          map $http_cf_connecting_ip $client_real_ip {
            default $http_cf_connecting_ip;
            "" $remote_addr;
          }
        '';

        upstreams = lib.mkMerge (
          map (service: {
            "${service.subdomain}".servers."127.0.0.1:${toString service.port}" = { };
          }) cfg.hosts
        );

        virtualHosts = lib.mkMerge (
          map (
            service:
            let
              domain = "${service.subdomain}.${consts.domain}";
              baseVhost = {
                forceSSL = true;
                http3 = true;
                kTLS = true;
                quic = true;
                useACMEHost = consts.domain;
                locations."/".proxyPass = "http://${service.subdomain}";
              };
            in
            {
              "${domain}" = lib.recursiveUpdate baseVhost service.config;
            }
          ) cfg.hosts
        );
      };

      tailscale.permitCertUid = "nginx";
    };

    dot.system.persistence.directories = [
      {
        directory = "/var/lib/acme";
        user = "acme";
        group = "acme";
        mode = "u=rwx,g=r,o=";
      }
    ];

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
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        inherit (consts) email;

        credentialFiles = {
          CF_DNS_API_TOKEN_FILE = config.sops.secrets."acme/cf-api-token".path;
        };
      };

      certs."${consts.domain}" = {
        inherit (consts) domain;
        extraDomainNames = [
          "*.${consts.domain}"
          "*.int.${consts.domain}"
        ];
      };
    };

    sops.secrets."acme/cf-api-token" = {
      sopsFile = ../../secrets/services/acme.yaml;
      owner = "acme";
      group = "acme";
      mode = "0400";
    };

    users.users.nginx.extraGroups = [ "acme" ];
  };
}
