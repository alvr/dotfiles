{
  flake.modules.nixos.gaming-clients = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      archisteamfarm
      heroic
      lutris
      mangohud
      protonup-qt
      samrewritten
      wine
      winetricks
    ];
  };
}
