{
  inputs,
  self,
  withSystem,
  ...
}:
let
  overlay = self.overlays.default;

  # Expose every omniflake package set as `pkgs.omniflake.<flake>`. The
  # attribute set is lazy, so only the flakes actually referenced are fetched.
  omniflakeOverlay = final: _prev: {
    omniflake = builtins.mapAttrs (
      _: flake: flake.packages.${final.stdenv.hostPlatform.system} or { }
    ) inputs.omniflake.flakes;
  };

  commonNixpkgs = { config, ... }: {
    nixpkgs = {
      pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);
      hostPlatform = config.dot.host.system;

      overlays = [
        inputs.chaotic.overlays.default
        omniflakeOverlay
        overlay
      ];
    };
  };
in
{
  flake.modules.nixos.base = commonNixpkgs;
  flake.modules.darwin.base = commonNixpkgs;
}
