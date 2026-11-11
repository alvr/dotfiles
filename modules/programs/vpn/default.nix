{ self, ... }:
{
  flake.modules.nixos.vpn = {
    imports = with self.modules.nixos; [
      cloudflare-warp
      tailscale-client
    ];
  };
}
