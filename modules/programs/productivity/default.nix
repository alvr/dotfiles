{ self, ... }:
{
  flake.modules = {
    nixos.productivity = {
      imports = with self.modules.nixos; [
        autofirma
        betterbird
        bitwarden
        brave-browser
        music
        obsidian
        transmission
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
