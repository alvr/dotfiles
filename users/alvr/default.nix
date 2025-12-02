{
  config,
  consts,
  pkgs,
  ...
}:
{
  sops.secrets.alvr-password = {
    neededForUsers = true;
  };

  users.users.alvr = {
    hashedPasswordFile = config.sops.secrets.alvr-password.path;
    isNormalUser = true;
    openssh.authorizedKeys.keys = consts.sshAuthorizedKeys;
    linger = true;
    shell = pkgs.fish;

    extraGroups = [
      "media"
      "wheel"
    ];
  };

  home-manager.users.alvr =
    { ... }:
    {
      imports = [ ./modules ];

      home = {
        username = "alvr";
        homeDirectory = "/home/alvr";

        stateVersion = "25.05";
      };

      programs.home-manager.enable = true;
      systemd.user.startServices = "sd-switch";
    };
}
