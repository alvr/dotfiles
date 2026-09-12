{
  flake.modules.nixos.fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      maple-mono.NF
      maple-mono.opentype
      (iosevka-bin.override { variant = "SS14"; })
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
    ];
  };
}
