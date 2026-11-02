{
  flake.modules = {
    nixos.herdr = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.herdr-desktop
      ];
    };

    homeManager.herdr = {
      programs.herdr = {
        enable = true;
        mutableSettings = true;

        settings = {
          onboarding = false;
          theme.name = "catppuccin";
        };
      };
    };
  };
}
