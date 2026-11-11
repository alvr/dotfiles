{ self, ... }:
let
  host = {
    name = "leviathan";
    state.version = "26.05";

    network.interfaces.eno1 = { };

    user = {
      email = "alvaro@alvr.dev";
      name = "Álvaro Salcedo García";
      gitSigningKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKzuOx+a7yFMdjZym16n4Jalv8RPv0y4xKAkPDgBlMM";
    };
  };
in
{
  flake.modules.nixos.leviathan = { config, ... }: {
    imports = with self.modules.nixos; [
      desktop
      self.diskoConfigurations.leviathan

      # Features
      wifi
    ];

    dot.host = host;

    dot.services.nextdns.profile = "c33aea";

    home-manager.users.${config.dot.host.user.alias} = {
      imports = with self.modules.homeManager; [
        desktop
      ];
    };
  };
}
