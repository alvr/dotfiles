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

  systemd.tmpfiles.rules = [
    "z /var/lib/private 0700 root root -"
    "z /var/cache/private 0700 root root -"
    "z /var/log/private 0700 root root -"
    "z /run/private 0700 root root -"
  ];
}
