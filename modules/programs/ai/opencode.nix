{
  flake.modules.homeManager.opencode = { pkgs, ... }: {
    home.packages = [ pkgs.opencode-desktop ];

    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;

      cli.theme = {
        name = "matugen";
        mode = "system";
      };
    };
  };
}
