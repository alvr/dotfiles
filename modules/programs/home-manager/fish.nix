{
  flake.modules.homeManager.fish = { lib, pkgs, ... }: {
    programs.fish = {
      enable = true;
      interactiveShellInit = "${lib.getExe pkgs.microfetch}";
    };
  };
}
