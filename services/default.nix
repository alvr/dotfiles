{ ... }:
{
  imports = [
    ./cloudflared.nix
    ./duckdns.nix
    ./jellyfin.nix
    ./openssh.nix
    ./qbittorrent.nix
    ./radarr.nix
    ./sonarr.nix
    ./tailscale.nix
    ./traefik.nix
    ./vaultwarden.nix
  ];
}
