{
  flake.modules.homeManager.bat = { pkgs, ... }: {
    programs.bat = {
      enable = true;

      extraPackages = [ pkgs.bat-extras.core ];
    };
  };
}
