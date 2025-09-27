{ ... }:
{
  imports = [
    ./cloudflare.nix
    ./duckdns.nix
    ./ssh.nix
    ./tailscale.nix
  ];
}
