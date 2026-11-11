{
  flake.modules.homeManager.mpv = {
    catppuccin.mpv.enable = true;

    programs.mpv = {
      enable = true;

      config = {
        hwdec = "auto-safe";
        vo = "gpu";
      };
    };

    xdg.mimeApps.defaultApplications = {
      "audio/*" = "mpv.desktop";
      "video/*" = "mpv.desktop";
    };
  };
}
