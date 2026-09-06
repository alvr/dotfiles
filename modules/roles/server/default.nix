{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.server =
    { config, lib, ... }:
    let
      network = config.dot.host.network;
    in
    {
      imports = with modules; [
        base
        deployable
        fail2ban
        impermanence
        openssh
        sops
      ];

      assertions = [
        {
          assertion = config.dot.host.network.domain != null;
          message = "servers must define dot.host.network.domain (used by the services attached to them)";
        }
        {
          assertion = config.dot.host.user.sshKeys != [ ];
          message = "servers must define at least one dot.host.user.sshKeys entry";
        }
        {
          assertion = lib.any (address: address != null) (
            [ network.wifi.ipv4.address ]
            ++ map (interface: interface.ipv4.address) (lib.attrValues network.interfaces)
          );
          message = "servers must define a static IPv4 address on wifi or a named network interface";
        }
      ];

      users.users.${config.dot.host.user.alias}.extraGroups = [ "media" ];
    };
}
