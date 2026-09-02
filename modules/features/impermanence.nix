{ inputs, ... }:
{
  flake.modules = {
    nixos.impermanence =
      { config, lib, ... }:
      let
        cfg = config.dot.system.persistence;
      in
      {
        imports = [ inputs.impermanence.nixosModules.impermanence ];

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

        config.environment.persistence."/nix/persist" = {
          hideMounts = true;

          directories = [
            "/etc/NetworkManager/system-connections"
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd"
          ]
          ++ cfg.directories;

          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
          ]
          ++ cfg.files;
        };
      };

    homeManager.impermanence =
      { config, lib, ... }:
      let
        cfg = config.dot.hm.system.persistence;
      in
      {
        options.dot.hm.system.persistence = {
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

        config.home.persistence."/nix/persist/users/${config.dot.host.user.alias}" = {
          inherit (cfg) directories files;
        };
      };
  };
}
