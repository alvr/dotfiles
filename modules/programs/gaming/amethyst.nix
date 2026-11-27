{
  flake.modules.homeManager.amethyst = { pkgs, ... }: {
    home.packages = [ pkgs.amethyst-mod-manager ];
  };
}
