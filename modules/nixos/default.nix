{ pkgs, ... }:
{
  imports = [
    ./boot.nix
    ./i18n.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./persistence.nix
    ./sops.nix


    ../../users/alvr.nix
    ../../services
  ];

  programs.fish.enable = true;
  users.mutableUsers = false;

  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  system.stateVersion = "25.05";
}
