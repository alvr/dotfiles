{ config, ... }:
let
  modules = config.flake.modules.nixos;
in
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      imports = with modules; [
        steam
      ];

      environment.systemPackages = with pkgs; [
        archisteamfarm
        heroic
        lutris
        mangohud
        protonup-qt
        samrewritten
        wine
        winetricks
      ];
    };
}
