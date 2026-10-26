{ self, ... }:
{
  flake.modules = {
    nixos.window-manager = {
      imports = with self.modules.nixos; [
        umbriel
        noctalia
        noctalia-greeter
      ];
    };

    homeManager.window-manager = {
      imports = with self.modules.homeManager; [
        umbriel
        noctalia
      ];
    };
  };
}
