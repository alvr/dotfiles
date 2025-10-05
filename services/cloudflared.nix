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
      package = pkgs.unstable.cloudflared;

      tunnels.apeiron = {
        credentialsFile = config.sops.secrets.cloudflare-tunnel.path;
        default = "http_status:404";
      };

      tunnels.apeiron-internal = {
        credentialsFile = config.sops.secrets.cloudflare-tunnel-internal.path;
        default = "http_status:404";
      };
    };

    sops.secrets = {
      cloudflare-cert = {
        format = "binary";
        sopsFile = ../secrets/cloudflare/cloudflare-cert;
        mode = "0400";
        restartUnits = [ "cloudflared.service" ];
      };

      cloudflare-tunnel = {
        format = "binary";
        sopsFile = ../secrets/cloudflare/cloudflare-tunnel;
        mode = "0400";
        restartUnits = [ "cloudflared.service" ];
      };

      cloudflare-tunnel-internal = {
        format = "binary";
        sopsFile = ../secrets/cloudflare/cloudflare-tunnel-internal;
        mode = "0400";
        restartUnits = [ "cloudflared.service" ];
      };
    };
  };
}
