{ config, ... }:
{
  dot.services = {
    cloudflared.enable = true;
    duckdns.enable = true;
    jellyfin.enable = true;
    openssh.enable = true;
    tailscale.enable = true;
    traefik.enable = true;
    vaultwarden.enable = true;
  };
}
