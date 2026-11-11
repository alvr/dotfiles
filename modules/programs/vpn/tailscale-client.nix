{
  flake.modules.nixos.tailscale-client = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
  };
}
