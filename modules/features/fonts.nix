{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts = {
        enableDefaultPackages = true;
        packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-emoji
          liberation_ttf
          fira-code
          fira-code-symbols
          jetbrains-mono
          (google-fonts.override { fonts = [ "Inter" ]; })
        ];
        fontconfig = {
          enable = true;
          defaultFonts = {
            serif = [ "Noto Serif" ];
            sansSerif = [ "Noto Sans" ];
            monospace = [ "JetBrains Mono" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };
    };
}
