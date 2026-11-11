{
  flake.modules = {
    nixos.betterbird = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.omniflake.betterbird-nix.betterbird
      ];
    };

    homeManager.betterbird.xdg.mimeApps.defaultApplications = {
      "message/rfc822" = "betterbird.desktop";
      "text/calendar" = "betterbird.desktop";
      "x-scheme-handler/mailto" = "betterbird.desktop";
      "x-scheme-handler/webcal" = "betterbird.desktop";
      "x-scheme-handler/webcals" = "betterbird.desktop";
    };
  };
}
