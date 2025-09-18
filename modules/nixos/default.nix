{ pkgs, ... }:
{
  imports = [
    ./_boot.nix
    ./_i18n.nix
    ./_networking.nix
    ./_nix.nix
    ./_packages.nix
    ./_persistence.nix
    ./_sops.nix

    ../../services/ssh.nix
    ../../services/tailscale.nix

    ../../users/alvr.nix
  ];

  programs.fish.enable = true;
  users.mutableUsers = false;

  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  system.stateVersion = "25.05";
}
