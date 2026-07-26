{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets.pat = {
    mode = "0600";
  };

  systemd.user.timers."flake-auto-update" = {
    Install.WantedBy = [ "timers.target" ];
    Unit.Description = "Weekly timer to update flake";
    Timer = {
      OnCalendar = "Wed,Sun *-*-* 01:00:00";
      Persistent = true;
      Unit = "flake-auto-update.service";
    };
  };

  systemd.user.services."flake-auto-update" = {
    Unit.Description = "Service to update flake.lock";

    Service = {
      Type = "oneshot";
      WorkingDirectory = "/nix/persist/dotfiles";
      Environment = [
        "KEY_FILE=%h/${config.sops.secrets."ssh-git-sign/prv".path}"
        "PAT_FILE=${config.sops.secrets.pat.path}"
        "PATH=${
          lib.makeBinPath (
            with pkgs;
            [
              bash
              coreutils
              git
              gnugrep
              gnused
              just
              nix
              openssh
            ]
          )
        }"
      ];

      ExecStart =
        let
          script = pkgs.writeScript "update-flake.sh" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail

            eval "$(${pkgs.openssh}/bin/ssh-agent -s)"
            ${pkgs.openssh}/bin/ssh-add "$KEY_FILE"

            ${pkgs.just}/bin/just fetch
            ${pkgs.just}/bin/just up

            ${pkgs.git}/bin/git config gpg.format ssh
            ${pkgs.git}/bin/git config user.signingkey "$KEY_FILE"

            if ! ${pkgs.git}/bin/git status --porcelain | ${pkgs.gnugrep}/bin/grep -q "flake.lock"; then
                kill "$SSH_AGENT_PID"
                exit 0
            fi

            ${pkgs.git}/bin/git add flake.lock
            ${pkgs.git}/bin/git commit -S -m "📦 update flake.lock"

            REMOTE_URL=$(${pkgs.git}/bin/git config --get remote.origin.url)
            PAT=$(${pkgs.coreutils}/bin/cat "$PAT_FILE")
            REMOTE_WITH_PAT=$(${pkgs.coreutils}/bin/echo "$REMOTE_URL" | ${pkgs.gnused}/bin/sed "s|https://|https://:$PAT@|")

            unset PAT

            ${pkgs.git}/bin/git push "$REMOTE_WITH_PAT"

            unset REMOTE_WITH_PAT
            kill "$SSH_AGENT_PID"
          '';
        in
        "${script}";
    };
  };
}
