{ self, ... }:
{
  flake.modules.homeManager.cli = {
    imports = with self.modules.homeManager; [
      bat
      btop
      delta
      eza
      fd
      fish
      fzf
      ripgrep
      yazi
      zoxide
    ];
  };
}
