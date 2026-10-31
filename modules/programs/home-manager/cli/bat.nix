{
  flake.modules.homeManager.bat = { pkgs, ... }: {
    catppuccin.bat.enable = true;

    programs.bat = {
      enable = true;

      extraPackages = [ pkgs.bat-extras.core ];
    };
  };
}
