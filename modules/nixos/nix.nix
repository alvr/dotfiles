{ inputs, ... }:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import ../../overlays { inherit inputs; };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      require-sigs = true;

      substituters = [
        "https://cache.nixos.org"
        "https://nyx-cache.chaotic.cx/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
      ];
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--delete-older-than 14d";
    flake = "/nix/persist/dotfiles";
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "03:00";
    flake = "git+https://codeberg.org/alvr/dotfiles.git";
  };
}
