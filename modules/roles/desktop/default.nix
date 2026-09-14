{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.desktop = { config, ... }: {
    imports = with modules; [
      base
      audio
      bluetooth
      fonts
      nextdns
      printing
      sops
    ];

    catppuccin.cursors.enable = true;

    users.users.${config.dot.host.user.alias}.extraGroups = [
      "audio"
      "camera"
      "lp"
      "scanner"
      "video"
    ];
  };
}
