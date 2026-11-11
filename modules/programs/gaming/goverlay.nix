{
  flake.modules.nixos.goverlay = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      goverlay
    ];
  };
}
