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
        ai-mcp
        ai-skills
        opencode
        pi
      ];
    };
  };
}
