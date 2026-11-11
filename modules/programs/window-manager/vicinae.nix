{
  flake.modules.homeManager.vicinae = {
    catppuccin.vicinae.enable = true;

    programs.vicinae = {
      enable = true;
      systemd.enable = true;
    };
  };
}
