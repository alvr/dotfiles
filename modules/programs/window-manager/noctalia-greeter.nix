{
  flake.modules.nixos.noctalia-greeter = { config, ... }: {
    services.displayManager.noctalia-greeter = {
      enable = true;
      passwordlessSyncUsers = [ config.dot.host.user.alias ];
      settings.session.default = "umbriel";
    };
  };
}
