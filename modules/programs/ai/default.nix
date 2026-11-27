{ self, ... }:
{
  flake.modules.homeManager.ai = {
    imports = with self.modules.homeManager; [
      ai-mcp
      ai-skills
      herdr
      opencode
      pi
      rtk
    ];
  };
}
