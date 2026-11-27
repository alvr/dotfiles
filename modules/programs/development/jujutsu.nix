{
  flake.modules.homeManager.jujutsu = { config, pkgs, ... }: {
    home.packages = [ pkgs.gg-jj ];

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
}
