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
      sshKeys = [ 
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNZNjk366JM+mYgVjm14hn5DGdJpHEX2wh6Iobeat+N"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCXPO6dERmCCAF29Elu3o+nqxserpQ1iOQ8oEScD2baRpshM9g6LrByHUkkBBwAKcC3V+9VzZFaJ0oWRX6RL/cI="
      ];
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
