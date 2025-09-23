{ config, ... }:
let
  home = config.home.username;
in
{
  sops.secrets."ssh-git-auth/pub" = {
    mode = "0640";
    path = "${home}/.ssh/ssh_git_auth.pub";
  };
  sops.secrets."ssh-git-auth/prv" = {
    mode = "0600";
    path = "${home}/.ssh/ssh_git_auth";
  };

  sops.secrets."ssh-git-sign/pub" = {
    mode = "0640";
    path = "${home}/.ssh/ssh_git_sign.pub";
  };
  sops.secrets."ssh-git-sign/prv" = {
    mode = "0600";
    path = "${home}/.ssh/ssh_git_sign";
  };
}
