{ self, ... }:
{
  flake.modules = {
    nixos.cli = {
      imports = with self.modules.nixos; [
        fish
      ];
    };

    homeManager.cli = {
      imports = with self.modules.homeManager; [
        bat
        btop
        delta
        eza
        fd
        fish
        fzf
        ripgrep
        starship
        yazi
        zoxide
      ];
    };
  };
}
