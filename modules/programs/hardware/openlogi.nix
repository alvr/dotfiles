{
  flake.modules.nixos.openlogi = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.openlogi ];
  };
}
