{ ... }:
{
  imports = [
    ./cloudflare.nix
    ./duckdns.nix
    ./openssh.nix
    ./tailscale.nix
    ./vaultwarden.nix
  ];
}
