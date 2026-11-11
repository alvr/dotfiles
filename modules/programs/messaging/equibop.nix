{
  flake.modules.homeManager.equibop =
    { config, ... }:
    let
      theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme";
    in
    {
      programs.equibop = {
        enable = true;

        equicord = {
          themes.${theme} = ''
            @import url("https://catppuccin.github.io/discord/dist/${theme}.css");
          '';
          settings = {
            autoUpdate = false;
            autoUpdateNotification = false;
            disableMinSize = true;

            plugins = {
              MessageLogger = {
                enabled = true;
                ignoreSelf = true;
              };
              FakeNitro.enabled = true;
            };

            enabledThemes = [ "${theme}.css" ];
          };
        };

        settings = {
          appBadge = false;
          arRPC = true;
          disableMinSize = true;
          staticTitle = true;
        };
      };
    };
}
