{ inputs, self, ... }:
{
  flake.modules = {
    nixos.sops = { config, ... }: {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFile = "${inputs.secrets}/${config.dot.host.name}/secrets.yaml";
        age.keyFile = "/nix/secret/age-keys.txt";
        gnupg.sshKeyPaths = [ ];
        useSystemdActivation = true;
      };

      systemd.tmpfiles.rules = [ "d /nix/secret 0700 root root -" ];
    };

    homeManager.sops = { config, ... }: {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        defaultSopsFile = "${inputs.secrets}/users/${config.dot.host.user.alias}/secrets.yaml";
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        gnupg.sshKeyPaths = [ ];
      };

      dot = self.lib.mkIfHmPersistence config {
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
