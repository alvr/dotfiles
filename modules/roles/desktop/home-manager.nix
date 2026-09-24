{ self, ... }:
{
  flake.modules.homeManager.desktop = {
    imports = with self.modules.homeManager; [
      base

      # Features
      sops

      # Programs
      cli
      development
      kitty
      starship
    ];
  };
}
