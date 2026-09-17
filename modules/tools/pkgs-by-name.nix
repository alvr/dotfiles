{ inputs, withSystem, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem = {
    pkgsDirectory = inputs.packages;
  };

  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:
      config.packages // { local = config.packages; }
    )
    // {
      # compat shim for sops-nix still on buildGo125Module, drop when upstream moves to buildGo126Module+
      # https://github.com/Mic92/sops-nix/issues/983
      buildGo125Module = prev.buildGoModule;
    };
}
