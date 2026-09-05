{ inputs, ... }:
{
  flake.modules.nixos.base = { config, pkgs, ... }: {
    sops.secrets.password = {
      neededForUsers = true;
      sopsFile = "${inputs.secrets}/users/${config.dot.host.user.alias}/secrets.yaml";
    };

    users.users.${config.dot.host.user.alias} = {
      isNormalUser = true;
      shell = pkgs.fish;
      hashedPasswordFile = config.sops.secrets.password.path;
      openssh.authorizedKeys.keys = config.dot.host.user.sshKeys;

      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };

  flake.modules.darwin.base = { config, ... }: {
    users.users.${config.dot.host.user.alias} = {
      home = "/Users/${config.dot.host.user.alias}";
    };

    system.primaryUser = config.dot.host.user.alias;
  };
}
