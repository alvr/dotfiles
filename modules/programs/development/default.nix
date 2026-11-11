{ self, ... }:
{
  flake.modules = {
    nixos.development = {
      imports = with self.modules.nixos; [
        git
        jadx
        jetbrains-toolbox
        jujutsu
      ];
    };

    homeManager.development = {
      imports = with self.modules.homeManager; [
        direnv
        gh
        git
        jujutsu
        nvchad
        vscodium
        zed
      ];
    };
  };
}
