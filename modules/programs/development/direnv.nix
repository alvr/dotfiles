{ self, ... }:
{
  flake.modules.homeManager.direnv = { config, ... }: {
    programs.direnv = {
      enable = true;
      enableFishIntegration = true;
    };

    dot = self.lib.mkIfHmPersistence config {
      hm.system.persistence.directories = [ ".local/share/direnv/allow" ];
    };
  };
}
