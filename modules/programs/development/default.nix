{ self, ... }:
{
  flake.modules.homeManager.development = {
    imports = with self.modules.homeManager; [
      direnv
      gh
      git
      jadx
      jetbrains-toolbox
      jujutsu
      nvchad
      vscodium
      wakatime
      zed
    ];
  };
}
