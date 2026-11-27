{ inputs, ... }:
{
  flake.modules.homeManager.hytale = { pkgs, ... }: {
    home.packages = [
      inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.hytale-launcher
    ];
  };
}
