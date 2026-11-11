{
  flake.modules.nixos.jetbrains-toolbox = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.jetbrains-toolbox ];
  };
}
