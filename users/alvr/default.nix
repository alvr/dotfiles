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
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = consts.sshAuthorizedKeys;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.alvr =
    { pkgs, ... }:
    {
      imports = [ ./modules ];

      home = {
        username = "alvr";
        homeDirectory = "/home/alvr";

        packages = with pkgs; [ btop ];

        stateVersion = "25.05";
      };

      programs.home-manager.enable = true;
      systemd.user.startServices = "sd-switch";
    };
}
