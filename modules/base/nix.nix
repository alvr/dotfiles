{ inputs, ... }:
let
  commonNix = {
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      require-sigs = true;
      fallback = true;

      substituters = [
        "https://cache.nixos.org"
        "https://nyx-cache.chaotic.cx/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    nix.registry.dotfiles.flake = inputs.self;

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--delete-older-than 14d";
    };
  };
in
{
  flake.modules.nixos.base = commonNix;
  flake.modules.darwin.base = commonNix;
}
