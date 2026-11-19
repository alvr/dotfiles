{ self, ... }:
{
  flake.modules.nixos.sonarr = self.lib.mkArr {
    name = "sonarr";
    port = 8989;
  };
}
