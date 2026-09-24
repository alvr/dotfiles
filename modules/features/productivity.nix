{ self, ... }:
{
  flake.modules.nixos.productivity = {
    imports = with self.modules.nixos; [
      betterbird
      browsers
    ];
  };
}
