{ self, ... }:
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      imports = with self.modules.nixos; [
        coolercontrol
        hytale
        openrgb
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
