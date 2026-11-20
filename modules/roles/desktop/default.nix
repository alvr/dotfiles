{ self, ... }:
let
  inherit (self.modules) nixos homeManager;

  shared = [
    "ai"
    "cli"
    "development"
    "messaging"
    "productivity"
    "window-manager"
  ];

  systemOnly = [
    "gaming"
    "hardware"
    "vpn"
  ];

  pick = module: names: map (name: module.${name}) names;
in
{
  flake.modules = {
    nixos.desktop = { config, ... }: {
      imports = pick nixos (
        [
          "base"
          "audio"
          "bluetooth"
          "bootvine"
          "fonts"
          "nextdns"
          "oo7"
          "printing"
          "sops"
          "stylix"
        ]
        ++ shared
        ++ systemOnly
      );

      stylix.autoEnable = false;

      users.users.${config.dot.host.user.alias}.extraGroups = [
        "audio"
        "camera"
        "lp"
        "scanner"
        "video"
      ];
    };

    homeManager.desktop = {
      imports = pick homeManager (
        [
          "base"
          "sops"
        ]
        ++ shared
      );

      stylix.targets = {
        lazygit.enable = true;
        starship.enable = true;
      };

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = true;
      };
    };
  };
}
