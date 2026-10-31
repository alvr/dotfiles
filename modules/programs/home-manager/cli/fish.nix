{ self, ... }:
{
  flake.modules.homeManager.fish =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      catppuccin.fish.enable = true;

      programs.fish = {
        enable = true;
        interactiveShellInit = "${lib.getExe pkgs.microfetch}";
      };

      dot = self.lib.mkIfHmPersistence config {
        hm.system.persistence.directories = [ ".local/share/fish" ];
      };
    };
}
