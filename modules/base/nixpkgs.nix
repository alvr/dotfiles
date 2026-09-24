{
  inputs,
  self,
  withSystem,
  ...
}:
let
  overlay = self.overlays.default;

  commonNixpkgs = { config, ... }: {
    nixpkgs = {
      pkgs = withSystem config.nixpkgs.hostPlatform.system ({ pkgs, ... }: pkgs);
      hostPlatform = config.dot.host.system;

      overlays = [
        inputs.chaotic.overlays.default
        inputs.nur.overlays.default
        overlay
      ];
    };
  };
in
{
  flake.modules.nixos.base = commonNixpkgs;
  flake.modules.darwin.base = commonNixpkgs;
}
