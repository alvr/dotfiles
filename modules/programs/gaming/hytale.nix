{
  flake.modules.nixos.hytale = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.omniflake.hytale-launcher-nix.hytale-launcher
    ];
  };
}
