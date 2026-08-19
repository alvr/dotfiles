{
  flake.modules.nixos.base = {
    security.doas.enable = true;
    users.mutableUsers = false;
  };
}
