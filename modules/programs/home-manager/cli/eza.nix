{
  flake.modules.homeManager.eza = {
    catppuccin.eza.enable = true;

    programs.eza = {
      enable = true;
      enableFishIntegration = true;
      git = true;
      icons = "auto";

      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };
  };
}
