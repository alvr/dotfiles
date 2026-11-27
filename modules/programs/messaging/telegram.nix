{
  flake.modules.homeManager.telegram = { pkgs, ... }: {
    home.packages = [ pkgs.telegram-desktop ];

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
    };
  };
}
