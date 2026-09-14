{ inputs, lib, ... }:
let
  commonHomeManager = config: {
    backupFileExtension = ".bak";
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${config.dot.host.user.alias}.home.stateVersion = config.dot.host.state.version;
  };

  catppuccinConfig = {
    enable = true;
    autoEnable = false;
    flavor = "macchiato";
    accent = "lavender";
  };
in
{
  flake.modules = {
    nixos.base = { config, ... }: {
      imports = [
        inputs.catppuccin.nixosModules.catppuccin
        inputs.home-manager.nixosModules.home-manager
      ];

      catppuccin = catppuccinConfig;

      home-manager = lib.mkMerge [
        (commonHomeManager config)
        { users.${config.dot.host.user.alias}.programs.home-manager.enable = true; }
      ];
    };

    darwin.base = { config, ... }: {
      imports = [
        inputs.catppuccin.darwinModules.catppuccin
        inputs.home-manager.darwinModules.home-manager
      ];

      catppuccin = catppuccinConfig;

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
        imports = [ inputs.catppuccin.homeModules.catppuccin ];

        catppuccin = catppuccinConfig;

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
