{
  config,
  inputs,
  withSystem,
  ...
}:
let
  localOverlay = config.flake.overlays.default;
  commonNixpkgs = { config, ... }: {
    nixpkgs = {
      pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);
      hostPlatform = config.dot.host.system;

      overlays = [
        inputs.chaotic.overlays.default
        inputs.nur.overlays.default
        localOverlay
      ];
    };
  };
in
{
  flake.modules.nixos.base = commonNixpkgs;
  flake.modules.darwin.base = commonNixpkgs;
}
