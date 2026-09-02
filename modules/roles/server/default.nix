{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.server = { config, ... }: {
    imports = with modules; [
      base
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
    ];
  };
}
