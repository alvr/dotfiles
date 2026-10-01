{ self, ... }:
{
  flake.modules.homeManager.zoxide = { config, ... }: {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    dot = self.lib.mkIfHmPersistence config {
      hm.system.persistence.directories = [ ".local/share/zoxide" ];
    };
  };
}
