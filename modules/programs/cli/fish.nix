{ self, ... }:
{
  flake.modules = {
    nixos.fish = { config, pkgs, ... }: {
      programs.fish.enable = true;
      users.users.${config.dot.host.user.alias}.shell = pkgs.fish;
    };

    homeManager.fish =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        programs.fish = {
          enable = true;
          interactiveShellInit = "${lib.getExe pkgs.microfetch}";
        };

        dot = self.lib.mkIfHmPersistence config {
          hm.system.persistence.directories = [ ".local/share/fish" ];
        };
      };
  };
}
