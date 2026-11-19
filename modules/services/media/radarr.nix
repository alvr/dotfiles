{ self, ... }:
{
  flake.modules.nixos.radarr = self.lib.mkArr {
    name = "radarr";
    port = 7878;
  };
}
