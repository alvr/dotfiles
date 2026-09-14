{
  flake.modules.nixos.betterbird = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.nur.repos.foolnotion.betterbird
    ];
  };
}
