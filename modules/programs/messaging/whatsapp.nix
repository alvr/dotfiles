{
  flake.modules.nixos.whatsapp = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      zapfast
    ];
  };
}
