{
  flake.modules.nixos.betterbird = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.omniflake.betterbird-nix.betterbird
    ];
  };
}
