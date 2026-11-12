{ inputs, ... }:
{
  flake.modules.nixos.stylix = { lib, pkgs, ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];

    stylix = {
      enable = true;
      autoEnable = lib.mkDefault false;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };
  };
}
