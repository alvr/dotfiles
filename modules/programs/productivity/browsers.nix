{
  flake.modules.nixos.browsers = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      brave-origin
      omniflake.zen-browser-flake.default
      omniflake.helium-browser-nix-flake.helium
    ];
  };
}
