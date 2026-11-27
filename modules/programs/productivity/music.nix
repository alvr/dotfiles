{
  flake.modules.homeManager.music = { pkgs, ... }: {
    home.packages = with pkgs; [
      spotifast
      spotify
    ];

    stylix.targets.ncspot.enable = true;

    programs.ncspot = {
      enable = true;
      settings.use_nerdfont = true;
    };
  };
}
