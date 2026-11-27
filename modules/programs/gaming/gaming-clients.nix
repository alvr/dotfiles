{
  flake.modules.homeManager.gaming-clients = { pkgs, ... }: {
    home.packages = with pkgs; [
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
