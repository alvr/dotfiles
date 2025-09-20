{ config, pkgs, ... }:
{
  sops.secrets = {
    cloudflare-cert = {
      format = "binary";
      sopsFile = ../secrets/cloudflare-cert;
    };

    cloudflare-tunnel = {
      format = "binary";
      sopsFile = ../secrets/cloudflare-tunnel;
    };

    cloudflare-tunnel-internal = {
      format = "binary";
      sopsFile = ../secrets/cloudflare-tunnel-internal;
    };
  };

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
}
