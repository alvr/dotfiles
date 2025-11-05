{ config, ... }:
{
  dot.services = {
    caddy.enable = true;
    cloudflared.enable = true;
    duckdns.enable = true;
    flaresolverr.enable = true;
    jellyfin.enable = true;
    jellyseerr.enable = true;
    openssh.enable = true;
    postgresql.enable = true;
    prowlarr.enable = true;
    qbittorrent.enable = true;
    radarr.enable = true;
    restic.enable = true;
    sonarr.enable = true;
    tailscale.enable = true;
    vaultwarden.enable = true;
  };
}
