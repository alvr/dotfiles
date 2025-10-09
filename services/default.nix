{ ... }:
{
  imports = [
    ./cloudflared.nix
    ./duckdns.nix
    ./jellyfin.nix
    ./openssh.nix
    ./radarr.nix
    ./sonarr.nix
    ./tailscale.nix
    ./traefik.nix
    ./vaultwarden.nix
  ];
}
