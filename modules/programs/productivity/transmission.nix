{
  flake.modules.homeManager.transmission = { pkgs, ... }: {
    home.packages = [ pkgs.transmission_4-qt ];

    xdg.mimeApps.defaultApplications = {
      "application/x-bittorrent" = "transmission-qt.desktop";
      "x-scheme-handler/magnet" = "transmission-qt.desktop";
    };
  };
}
