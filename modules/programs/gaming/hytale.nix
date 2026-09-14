{
  flake.modules.nixos.hytale = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.nur.repos.forkprince.hytale
    ];
  };
}
