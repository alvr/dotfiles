{ inputs, self, ... }:
let
  overlay = self.overlays.default;

  commonNixpkgs = { config, ... }: {
    nix.settings = {
      extra-substituters = [ "https://nyx-cache.chaotic.cx" ];
      extra-trusted-public-keys = [ "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=" ];
    };

    nixpkgs = {
      config.allowUnfree = true;
      hostPlatform = config.dot.host.system;

      overlays = [
        inputs.chaotic.overlays.default
        overlay
      ];
    };
  };
in
{
  flake.modules.nixos.base = commonNixpkgs;
  flake.modules.darwin.base = commonNixpkgs;
}
