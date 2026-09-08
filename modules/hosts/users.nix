{ inputs, ... }:
{
  flake.modules.nixos.base = { config, pkgs, ... }: {
    sops.secrets."${config.dot.host.user.alias}-password" = {
      key = config.dot.host.user.alias;
      neededForUsers = true;
      sopsFile = "${inputs.secrets}/common/user-passwords.yaml";
    };

    users.users.${config.dot.host.user.alias} = {
      isNormalUser = true;
      shell = pkgs.fish;
      hashedPasswordFile = config.sops.secrets."${config.dot.host.user.alias}-password".path;
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
