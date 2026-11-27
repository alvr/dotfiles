{ self, ... }:
{
  flake.modules.nixos.hardware = {
    imports = with self.modules.nixos; [
      fwupd
      openlogi
    ];
  };
}
