{ config, ... }:
let
  ssh = ".ssh";
  sshDir = "${config.home.username}/${ssh}";
in
{
  sops.secrets = {
    "ssh-git-auth/pub" = {
      mode = "0640";
      path = "${sshDir}/ssh_git_auth.pub";
    };
    "ssh-git-auth/prv" = {
      mode = "0600";
      path = "${sshDir}/ssh_git_auth";
    };

    "ssh-git-sign/pub" = {
      mode = "0640";
      path = "${sshDir}/ssh_git_sign.pub";
    };
    "ssh-git-sign/prv" = {
      mode = "0600";
      path = "${sshDir}/ssh_git_sign";
    };
  };

  dot.hm.security.sops.enable = true;

  dot.hm.system.persistence = {
    enable = true;
    directories = [ ssh ];
  };
}
