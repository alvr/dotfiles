{
  flake.modules = {
    nixos.music = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        spotifast
        spotify
      ];
    };

    homeManager.music = {
      programs.ncspot = {
        enable = true;
        settings.use_nerdfont = true;
      };
    };
  };
}
