{
  flake.modules.homeManager.vscodium = {
    programs.vscodium.enable = true;

    xdg.mimeApps.defaultApplications = {
      "application/json" = "codium.desktop";
      "application/x-shellscript" = "codium.desktop";
      "text/markdown" = "codium.desktop";
      "text/plain" = "codium.desktop";
    };
  };
}
