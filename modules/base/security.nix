{
  flake.modules.nixos.base = { config, ... }: {
    security = {
      doas = {
        enable = true;
        extraRules = [
          {
            users = [ config.dot.host.user.alias ];
            keepEnv = true;
            noPass = false;
          }
        ];
      };
      sudo.enable = false;
    };
    users.mutableUsers = false;
  };
}
