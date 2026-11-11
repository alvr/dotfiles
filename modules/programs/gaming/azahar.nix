{
  flake.modules.nixos.azahar = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.azahar
    ];
  };
}
