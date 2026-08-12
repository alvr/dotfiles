{ ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/nix/secret/age-keys.txt";
    gnupg.sshKeyPaths = [ ];
  };
}
