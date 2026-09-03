{
  flake.modules.nixos.base = {
    security = {
      doas = {
        enable = true;
        wheelNeedsPassword = false;
      };
      sudo.enable = false;
    };
    users.mutableUsers = false;
  };
}
