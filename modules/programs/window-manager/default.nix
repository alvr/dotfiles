{ self, ... }:
{
  flake.modules = {
    nixos.window-manager = {
      imports = with self.modules.nixos; [
        file-manager
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
