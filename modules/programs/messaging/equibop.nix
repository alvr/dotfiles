{
  flake.modules.homeManager.equibop = {
    programs.equibop = {
      enable = true;

      equicord = {
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
        };
      };

      settings = {
        appBadge = true;
        arRPC = true;
        disableMinSize = false;
        staticTitle = false;
      };
    };
  };
}
