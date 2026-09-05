{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.server = { config, ... }: {
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
    ];

    users.users.${config.dot.host.user.alias}.extraGroups = [ "media" ];
  };
}
