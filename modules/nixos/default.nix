{ lib, ... }:
{
  imports = lib.dot.import ./. ++ [
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
