{ ... }:
{
  imports = [
    ./boot.nix
    ./fail2ban.nix
    ./i18n.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./persistence.nix
    ./sops.nix

    ../../services
    ../../users
  ];

  programs.fish.enable = true;
  users.mutableUsers = false;

  security.sudo = {
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };

  system.stateVersion = "25.05";
}
