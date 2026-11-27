{ self, ... }:
{
  flake.modules = {
    nixos.gaming = {
      imports = with self.modules.nixos; [
        coolercontrol
        openrgb
        steam
      ];
    };

    homeManager.gaming = {
      imports = with self.modules.homeManager; [
        amethyst
        azahar
        gaming-clients
        goverlay
        hytale
        ryubing
      ];
    };
  };
}
