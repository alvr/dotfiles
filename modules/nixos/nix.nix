{ inputs, pkgs, ... }:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import ../../overlays { inherit inputs; };
  };

  nix = {
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
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
    flake = "git+https://git.alvr.dev/alvr/dotfiles.git";
  };
}
