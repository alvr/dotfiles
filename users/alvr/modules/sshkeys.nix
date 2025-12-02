{ ... }:
{
  dot.hm.security.sops.enable = true;

  sops.secrets = {
    "ssh-git-auth/pub" = {
      mode = "0640";
      path = ".ssh/ssh_git_auth.pub";
    };
    "ssh-git-auth/prv" = {
      mode = "0600";
      path = ".ssh/ssh_git_auth";
    };

    "ssh-git-sign/pub" = {
      mode = "0640";
      path = ".ssh/ssh_git_sign.pub";
    };
    "ssh-git-sign/prv" = {
      mode = "0600";
      path = ".ssh/ssh_git_sign";
    };
  };
}
