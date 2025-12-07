{ config, lib, ... }:
let
  cfg = config.dot.services.cloudflared;
in
{
  options.dot.services.cloudflared = {
    enable = lib.mkEnableOption "Enable Cloudflared service";

    ingress = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      certificateFile = config.sops.secrets.cloudflare-cert.path;

      tunnels.apeiron = {
        credentialsFile = config.sops.secrets.cloudflare-tunnel.path;
        default = "http_status:404";

        ingress = lib.genAttrs cfg.ingress (domain: {
          service = "https://localhost";
          originRequest = {
            httpHostHeader = domain;
            originServerName = domain;
            noTLSVerify = false;
          };
        });
      };
    };

    sops.secrets =
      let
        cloudflare-secret = {
          format = "binary";
          mode = "0400";
          restartUnits = [ "cloudflared-tunnel-apeiron.service" ];
        };
      in
      {
        cloudflare-cert = cloudflare-secret // {
          sopsFile = ../../secrets/cloudflare/cloudflare-cert;
        };

        cloudflare-tunnel = cloudflare-secret // {
          sopsFile = ../../secrets/cloudflare/cloudflare-tunnel;
        };
      };
  };
}
