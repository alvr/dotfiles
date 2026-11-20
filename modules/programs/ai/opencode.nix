{
  flake.modules = {
    nixos.opencode = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        opencode-desktop
      ];
    };

    homeManager.opencode = {
      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;

        cli.theme = {
          name = "matugen";
          mode = "system";
        };
      };
    };
  };
}
