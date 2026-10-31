{ self, ... }:
{
  flake.modules.homeManager.yazi = { config, ... }: {
    catppuccin.yazi.enable = true;

    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "y";
    };

    dot = self.lib.mkIfHmPersistence config {
      hm.system.persistence.directories = [ ".local/state/yazi" ];
    };
  };
}
