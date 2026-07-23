{
  config,
  consts,
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import ../../overlays { inherit inputs; };
  };

  nix = {
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      require-sigs = true;

      substituters = [
        "https://cache.nixos.org"
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
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
    flake = "git+https://git.${consts.domain}/alvr/dotfiles.git";
  };
}
