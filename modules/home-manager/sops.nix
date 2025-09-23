{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/users/${config.home.username}/secrets.yaml;
    age.keyFile = "/nix/persist/users/${config.home.username}/.age-keys.txt";
    gnupg.sshKeyPaths = [ ];
  };
}
