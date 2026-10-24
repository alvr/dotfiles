{ self, ... }:
{
  flake.modules = {
    nixos.window-manager = {
      imports = with self.modules.nixos; [
        umbriel
      ];
    };

    homeManager.window-manager = {
      imports = with self.modules.homeManager; [
        umbriel
      ];
    };
  };
}
