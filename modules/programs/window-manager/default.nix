{ self, ... }:
{
  flake.modules = {
    nixos.window-manager = {
      imports = with self.modules.nixos; [
        noctalia
        noctalia-greeter
        umbriel
      ];
    };

    homeManager.window-manager = {
      imports = with self.modules.homeManager; [
        file-manager
        noctalia
        umbriel
        vicinae
      ];
    };
  };
}
