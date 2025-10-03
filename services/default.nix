{ ... }:
{
  imports = [
    ./cloudflared.nix
    ./duckdns.nix
    ./jellyfin.nix
    ./openssh.nix
    ./tailscale.nix
    ./traefik.nix
    ./vaultwarden.nix
  ];
}
