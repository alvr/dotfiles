{
  flake.modules.homeManager.ryubing = { pkgs, ... }: {
    home.packages = [ pkgs.ryubing ];
  };
}
