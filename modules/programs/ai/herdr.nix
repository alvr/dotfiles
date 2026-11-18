{
  flake.modules.nixos.herdr = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.herdr-desktop
    ];
  };
}
