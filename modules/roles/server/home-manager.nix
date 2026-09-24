{ self, ... }:
{
  flake.modules.homeManager.server = {
    imports = with self.modules.homeManager; [
      base

      # Features
      sops
      impermanence

      # Programs
      cli
      direnv
      git
    ];
  };
}
