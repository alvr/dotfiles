{ config, ... }:
let
  host = {
    name = "apeiron";
    state.version = "25.05";

    network = {
      domain = "alvr.dev";
      wifi.ipv4.address = "192.168.1.200";
    };

    user = {
      email = "alvaro@alvr.dev";
      name = "Álvaro Salcedo García";
    };
  };

  inherit (config) flake;
  inherit (config.flake) modules;
in
{
  flake.modules.nixos.apeiron = { config, ... }: {
    imports = with modules.nixos; [
      server
      flake.diskoConfigurations.apeiron

      # Features
      podman
      wifi
    ];

    dot.host = host;

    home-manager.users.${config.dot.host.user.alias} = {
      imports = with modules.homeManager; [
        server
      ];
    };
  };
}
