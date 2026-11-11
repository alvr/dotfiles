{ self, ... }:
{
  flake.modules.nixos.gaming = {
    imports = with self.modules.nixos; [
      amethyst
      azahar
      gaming-clients
      coolercontrol
      goverlay
      hytale
      openrgb
      ryubing
      steam
    ];
  };
}
