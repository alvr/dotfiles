{
  flake.modules = {
    nixos.jujutsu = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        gg-jj
        jjui
      ];
    };

    homeManager.jujutsu = { config, ... }: {
      programs.jujutsu = {
        enable = true;

        settings.user = {
          inherit (config.dot.host.user) name email;
        };
      };
    };
  };
}
