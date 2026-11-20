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
    nixos.desktop = { config, pkgs, ... }: {
      imports = pick nixos (
        [
          "base"
          "audio"
          "bluetooth"
          "bootvine"
          "nextdns"
          "oo7"
          "printing"
          "sops"
          "theming"
        ]
        ++ shared
        ++ systemOnly
      );

      environment.systemPackages = [ pkgs.wl-clipboard ];

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
          "theming"
        ]
        ++ shared
      );

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = true;
      };
    };
  };
}
