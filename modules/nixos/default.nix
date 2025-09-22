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

    ../../services/cloudflare.nix
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
