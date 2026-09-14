{
  flake.modules.homeManager.fish = { lib, pkgs, ... }: {
    catppuccin.fish.enable = true;

    programs.fish = {
      enable = true;
      interactiveShellInit = "${lib.getExe pkgs.microfetch}";
    };
  };
}
