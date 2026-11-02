{ self, ... }:
{
  flake.modules = {
    nixos.ai = {
      imports = with self.modules.nixos; [
        herdr
        opencode
      ];
    };

    homeManager.ai = {
      imports = with self.modules.homeManager; [
        herdr
        opencode
        pi
      ];
    };
  };
}
