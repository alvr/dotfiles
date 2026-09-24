{ self, ... }:
let
  host = {
    name = "leviathan";
    state.version = "26.05";

    network.interfaces.eno1 = { };

    user = {
      email = "alvaro@alvr.dev";
      name = "Álvaro Salcedo García";
    };
  };
in
{
  flake.modules.nixos.leviathan = { config, ... }: {
    imports = with self.modules.nixos; [
      desktop
      self.diskoConfigurations.leviathan

      # Features
      gaming
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
