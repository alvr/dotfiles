{
  flake.modules.homeManager.vscodium = {
    catppuccin.vscodium.profiles.default = {
      enable = true;
      icons.enable = true;
    };

    programs.vscodium.enable = true;

    xdg.mimeApps.defaultApplications = {
      "application/json" = "codium.desktop";
      "application/x-shellscript" = "codium.desktop";
      "text/markdown" = "codium.desktop";
      "text/plain" = "codium.desktop";
    };
  };
}
