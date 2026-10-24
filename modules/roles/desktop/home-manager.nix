{ self, ... }:
{
  flake.modules.homeManager.desktop = {
    imports = with self.modules.homeManager; [
      base

      # Features
      sops
      window-manager

      # Programs
      cli
      development
      kitty
      starship
    ];
  };
}
