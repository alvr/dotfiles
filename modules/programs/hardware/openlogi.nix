{
  flake.modules.nixos.openlogi = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [ openlogi ];
  };
}
