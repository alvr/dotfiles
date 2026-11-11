{
  flake.modules = {
    nixos.telegram = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        telegram-desktop
      ];
    };

    homeManager.telegram.xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
    };
  };
}
