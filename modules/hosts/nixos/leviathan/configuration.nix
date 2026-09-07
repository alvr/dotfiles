{ config, ... }:
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

  inherit (config) flake;
  inherit (config.flake) modules;
in
{
  flake.modules.nixos.leviathan = { config, ... }: {
    imports = with modules.nixos; [
      desktop
      flake.diskoConfigurations.leviathan

      # Features
      wifi
    ];

    dot.host = host;

    # TODO: replace with real NextDNS profile ID from my.nextdns.io (6 chars).
    dot.services.nextdns.profile = "000000";

    home-manager.users.${config.dot.host.user.alias} = {
      imports = with modules.homeManager; [
        desktop
      ];
    };
  };
}
