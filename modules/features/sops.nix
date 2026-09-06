{ inputs, ... }:
{
  flake.modules = {
    nixos.sops = { config, ... }: {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = "${inputs.secrets}/${config.dot.host.name}/secrets.yaml";
        age.keyFile = "/nix/secret/age-keys.txt";
        gnupg.sshKeyPaths = [ ];
      };
    };

    homeManager.sops = { config, ... }: {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        defaultSopsFile = "${inputs.secrets}/users/${config.dot.host.user.alias}/secrets.yaml";
        age.keyFile = "/home/${config.dot.host.user.alias}/.config/sops/age/keys.txt";
        age.generateKey = true;
        gnupg.sshKeyPaths = [ ];
      };

      dot = inputs.self.lib.mkIfPersistence config {
        hm.system.persistence.files = [ ".config/sops/age/keys.txt" ];
      };
    };

    darwin.sops = { config, ... }: {
      imports = [ inputs.sops-nix.darwinModules.sops ];

      sops = {
        defaultSopsFile = "${inputs.secrets}/${config.dot.host.name}/secrets.yaml";
        age.keyFile = "/Users/${config.dot.host.user.alias}/.config/sops/age/keys.txt";
        gnupg.sshKeyPaths = [ ];
      };
    };
  };
}
