{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.cloudflared;
in
{
  options.dot.services.cloudflared = {
    enable = lib.mkEnableOption "Enable Cloudflared service";
  };

  config = lib.mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      certificateFile = config.sops.secrets.cloudflare-cert.path;
      package = pkgs.cloudflared;

      tunnels.apeiron = {
        credentialsFile = config.sops.secrets.cloudflare-tunnel.path;
        default = "http_status:404";
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
