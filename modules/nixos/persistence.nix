{ config, lib, ... }:
{
  options.dot.system.persistence = {
    directories = lib.mkOption {
      type = lib.types.listOf (
        lib.types.oneOf [
          lib.types.str
          (lib.types.attrsOf lib.types.anything)
        ]
      );
      default = [ ];
    };
    files = lib.mkOption {
      type = lib.types.listOf (
        lib.types.oneOf [
          lib.types.str
          (lib.types.attrsOf lib.types.anything)
        ]
      );
      default = [ ];
    };
  };

  config = {
    environment.persistence."/nix/persist" = {
      hideMounts = true;

      directories = [
        "/etc/NetworkManager/system-connections"
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd"
      ]
      ++ config.dot.system.persistence.directories;

      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
      ]
      ++ config.dot.system.persistence.files;
    };
  };
}
