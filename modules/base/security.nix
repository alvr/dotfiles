{
  flake.modules.nixos.base = { config, ... }: {
    security = {
      doas = {
        enable = true;
        extraRules = [
          {
            users = [ config.dot.host.user.alias ];
            keepEnv = true;
            persist = true;
          }
        ];
      };
      sudo.enable = false;
    };
    users.mutableUsers = false;
  };
}
