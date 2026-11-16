{
  flake.modules.nixos.oo7 = {
    services.oo7.enable = true;
    security.pam.services.greetd.oo7.enable = true;
  };
}
