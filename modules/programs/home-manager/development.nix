{ self, ... }:
{
  flake.modules.homeManager.development = {
    imports = with self.modules.homeManager; [
      direnv
      gh
      git
      lazygit
      nvchad
    ];
  };
}
