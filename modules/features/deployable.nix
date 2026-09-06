{
  config,
  inputs,
  lib,
  ...
}:
let
  deployableConfigurations = lib.filterAttrs (
    _name: nixosConfiguration: builtins.elem "deployable" nixosConfiguration.config.system.nixos.tags
  ) config.flake.nixosConfigurations;

  hostAddress =
    host:
    lib.findFirst (address: address != null)
      (throw "The deployable host ${host.name} must define dot.host.network.wifi.ipv4.address or an IPv4 address on a named network interface")
      (
        [ host.network.wifi.ipv4.address ]
        ++ map (interface: interface.ipv4.address) (lib.attrValues host.network.interfaces)
      );

  deployNode =
    _name: nixosConfiguration:
    let
      host = nixosConfiguration.config.dot.host;
    in
    {
      hostname = hostAddress host;
      sshUser = host.user.alias;
      sudo = "doas -u";
      sshOpts = [
        "-p"
        (toString host.network.ssh.port)
      ];
      profiles = {
        system = {
          user = "root";
          groups = [ "server" ];
          remoteBuild = true;
          path = inputs.deploy-rs.lib.${host.system}.activate.nixos nixosConfiguration;
        };

        bootstrap = {
          user = "root";
          groups = [ "bootstrap" ];
          remoteBuild = false;
          path = inputs.deploy-rs.lib.${host.system}.activate.nixos nixosConfiguration;
        };
      };
    };
in
{
  flake = {
    deploy.nodes = lib.mapAttrs deployNode deployableConfigurations;

    modules.nixos.deployable =
      { config, ... }:
      {
        config.system.nixos.tags = [ "deployable" ];
        config.nix.settings.trusted-users = [ config.dot.host.user.alias ];
      };
  };

  perSystem =
    { system, ... }:
    {
      apps.deploy = {
        type = "app";
        program = "${lib.getExe inputs.deploy-rs.packages.${system}.default}";
      };

      checks = inputs.deploy-rs.lib.${system}.deployChecks config.flake.deploy;
    };
}
