{
  flake.modules = {
    nixos.jujutsu = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        gg-jj
      ];
    };

    homeManager.jujutsu = { config, ... }: {
      stylix.targets.jjui.enable = true;

      programs = {
        jjui.enable = true;

        jujutsu = {
          enable = true;

          settings.user = {
            inherit (config.dot.host.user) name email;
          };
        };
      };
    };
  };
}
