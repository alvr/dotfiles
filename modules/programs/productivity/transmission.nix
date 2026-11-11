{
  flake.modules = {
    nixos.transmission = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.transmission_4-qt
      ];
    };

    homeManager.transmission.xdg.mimeApps.defaultApplications = {
      "application/x-bittorrent" = "transmission-qt.desktop";
      "x-scheme-handler/magnet" = "transmission-qt.desktop";
    };
  };
}
