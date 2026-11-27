{ inputs, ... }:
{
  flake.modules.homeManager.betterbird = { pkgs, ... }: {
    home.packages = [
      inputs.betterbird.packages.${pkgs.stdenv.hostPlatform.system}.betterbird
    ];

    xdg.mimeApps.defaultApplications = {
      "message/rfc822" = "betterbird.desktop";
      "text/calendar" = "betterbird.desktop";
      "x-scheme-handler/mailto" = "betterbird.desktop";
      "x-scheme-handler/webcal" = "betterbird.desktop";
      "x-scheme-handler/webcals" = "betterbird.desktop";
    };
  };
}
