{
  flake.modules.homeManager.jetbrains-toolbox = { pkgs, ... }: {
    home.packages = [ pkgs.jetbrains-toolbox ];
  };
}
