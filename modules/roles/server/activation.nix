{ lib, ... }:
{
  flake.modules.nixos.server = {
    system.activationScripts.fix-private-permissions = lib.stringAfter [ "var" ] ''
      for dir in /var/lib/private /var/cache/private /var/log/private /run/private; do
        mkdir -p "$dir"
        chmod 0700 "$dir"
      done
    '';
  };
}
