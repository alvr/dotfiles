{ ... }:
{
  imports = [
    ./cloudflare.nix
    ./duckdns.nix
    ./jellyfin.nix
    ./openssh.nix
    ./tailscale.nix
    ./vaultwarden.nix
  ];
}
