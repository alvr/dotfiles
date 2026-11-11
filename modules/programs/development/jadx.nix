{
  flake.modules.nixos.jadx = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.jadx ];
  };
}
