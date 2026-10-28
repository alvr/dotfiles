{
  flake.modules.nixos.noctalia-greeter = { config, ... }: {
    services.displayManager.noctalia-greeter = {
      enable = true;
      passwordlessSyncUsers = [ config.dot.host.user.alias ];
      settings = {
        session.default = "umbriel";
        output.name = "DP-3";
        keyboard = {
          layout = "es";
          options = "lv3:rwin_switch";
        };
      };
    };
  };
}
