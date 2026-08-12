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

  system.activationScripts.fix-private-permissions = lib.stringAfter [ "var" ] ''
    for dir in /var/lib/private /var/cache/private /var/log/private /run/private; do
      mkdir -p "$dir"
      chmod 0700 "$dir"
    done
  '';
}
