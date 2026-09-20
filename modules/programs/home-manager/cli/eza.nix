{
  flake.modules.homeManager.eza = {
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
