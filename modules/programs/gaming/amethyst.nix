{
  flake.modules.nixos.amethyst = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.amethyst-mod-manager
    ];
  };
}
