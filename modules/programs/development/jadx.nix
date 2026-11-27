{
  flake.modules.homeManager.jadx = { pkgs, ... }: {
    home.packages = [ pkgs.jadx ];
  };
}
