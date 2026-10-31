{
  inputs,
  lib,
  self,
  ...
}:
let
  commonHomeManager = config: {
    backupFileExtension = ".bak";
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${config.dot.host.user.alias}.home.stateVersion = config.dot.host.state.version;
  };
in
{
  flake.modules = {
    nixos.base = { config, ... }: {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        self.modules.nixos.catppuccin
      ];

      home-manager = lib.mkMerge [
        (commonHomeManager config)
        { users.${config.dot.host.user.alias}.programs.home-manager.enable = true; }
      ];
    };

    darwin.base = { config, ... }: {
      imports = [
        inputs.home-manager.darwinModules.home-manager
        self.modules.darwin.catppuccin
      ];

      home-manager = lib.mkMerge [
        (commonHomeManager config)
        { users.${config.dot.host.user.alias}.targets.darwin.linkApps.enable = true; }
      ];
    };

    homeManager.base =
      {
        config,
        pkgs,
        osConfig,
        ...
      }:
      {
        imports = [ self.modules.homeManager.catppuccin ];

        dot.host = osConfig.dot.host;

        systemd.user.startServices = "sd-switch";

        home = {
          username = config.dot.host.user.alias;
          homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "/Users/${config.dot.host.user.alias}"
            else
              "/home/${config.dot.host.user.alias}";
          stateVersion = config.dot.host.state.version;
        };
      };
  };
}
