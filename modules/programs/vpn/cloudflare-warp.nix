{
  flake.modules.nixos.cloudflare-warp = {
    services.cloudflare-warp = {
      enable = true;
      openFirewall = true;
    };
  };
}
