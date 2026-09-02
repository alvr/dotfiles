{ inputs, lib, ... }:
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
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = lib.recursiveUpdate (commonHomeManager config) {
        users.${config.dot.host.user.alias}.programs.home-manager.enable = true;
      };
    };

    darwin.base = { config, ... }: {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      home-manager = lib.recursiveUpdate (commonHomeManager config) {
        users.${config.dot.host.user.alias}.targets.darwin.linkApps.enable = true;
      };
    };

    homeManager.base =
      {
        config,
        pkgs,
        osConfig,
        ...
      }:
      {
        dot.host = osConfig.dot.host;

        systemd.user.startServices = "sd-switch";

        home = {
          username = config.dot.host.user.alias;
          homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "/Users/${config.dot.host.user.alias}"
            else
              "/home/${config.dot.host.user.alias}";
          packages = [ pkgs.home-manager ];
          stateVersion = config.dot.host.state.version;
        };
      };
  };
}
