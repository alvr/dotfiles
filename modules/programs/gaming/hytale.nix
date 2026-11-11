{ inputs, ... }:
{
  flake.modules.nixos.hytale = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.hytale-launcher
    ];
  };
}
