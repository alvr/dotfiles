{
  flake.modules.homeManager.azahar = { pkgs, ... }: {
    home.packages = [ pkgs.azahar ];
  };
}
