{
  flake.modules.nixos.ryubing = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.ryubing
    ];
  };
}
