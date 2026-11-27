{ self, ... }:
{
  flake.modules = {
    nixos.productivity = {
      imports = with self.modules.nixos; [
        autofirma
        brave-browser
        obsidian
        x-craft
      ];
    };

    homeManager.productivity = {
      imports = with self.modules.homeManager; [
        autofirma
        betterbird
        bitwarden
        ghostty
        brave-browser
        mpv
        music
        nextcloud-client
        obs-studio
        obsidian
        transmission
        x-craft
        zen-browser
      ];
    };

    darwin.productivity = {
      imports = with self.modules.darwin; [
        obsidian
      ];
    };
  };
}
