{
  flake.modules.homeManager.goverlay = { pkgs, ... }: {
    home.packages = [ pkgs.goverlay ];
  };
}
