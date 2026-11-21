{
  config.flake.lib.mkGitCredential =
    {
      pkgs,
      user,
      secret,
    }:
    pkgs.writeShellScript "git-credential-${user}" ''
      if [ "$1" = get ]; then
        printf 'username=%s\n' ${pkgs.lib.escapeShellArg user}
        printf 'password=%s\n' "$(${pkgs.coreutils}/bin/cat ${pkgs.lib.escapeShellArg secret})"
      fi
    '';
}
