{
  config,
  consts,
  inputs,
  pkgs,
  ...
}:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import ../../overlays { inherit inputs; };
  };

  nix = {
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      substituters = [ "https://attic.xuyh0120.win/lantian" ];
      trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--delete-older-than 14d";
    flake = "/nix/persist/dotfiles";
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "03:00";
    flake = "git+https://git.${consts.domain}/alvr/dotfiles.git";
  };

  sops.secrets.upgrade-notify-url = {
    sopsFile = ../../secrets/upgrade-notify.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  systemd.services.nixos-upgrade-notify = {
    description = "Notify NixOS upgrade";
    after = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];
    path = with pkgs; [
      coreutils
      curl
      dix
      systemd
    ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          script = pkgs.writeShellScript "upgrade-notify.sh" ''
            set -uo pipefail

            NTFY_URL=$(cat ${config.sops.secrets.upgrade-notify-url.path})
            STATUS=$(systemctl is-failed nixos-upgrade.service 2>/dev/null || echo "unknown")

            if [ "$STATUS" = "failed" ] ; then
              LOG=$(journalctl -u nixos-upgrade.service -n 50 --no-pager 2>/dev/null || echo "No log available")
              curl -s --max-time 30 -d "NixOS upgrade failed:
              $LOG" "$NTFY_URL"
            else
              PREVIOUS_PROFILE=$(ls -v1d /nix/var/nix/profiles/system-*-link 2>/dev/null | sed -n 'x;$p' || true)
              PREVIOUS_SYSTEM=$( [ -n "$PREVIOUS_PROFILE" ] && readlink -f "$PREVIOUS_PROFILE" 2>/dev/null || echo "" )
              CURRENT_SYSTEM=$(readlink -f /run/current-system 2>/dev/null || echo "")

              if [ -z "$CURRENT_SYSTEM" ] ; then
                curl -s --max-time 30 -d "NixOS upgrade succeeded: could not determine current system" "$NTFY_URL"
              elif [ -z "$PREVIOUS_SYSTEM" ] ; then
                curl -s --max-time 30 -d "NixOS upgrade succeeded: could not determine previous system" "$NTFY_URL"
              elif [ "$PREVIOUS_SYSTEM" = "$CURRENT_SYSTEM" ] ; then
                curl -s --max-time 30 -d "NixOS upgrade succeeded: no packages updated" "$NTFY_URL"
              else
                DIFF=$(dix "$PREVIOUS_SYSTEM" "$CURRENT_SYSTEM" 2>/dev/null || echo "")
                if [ -z "$DIFF" ] ; then
                  curl -s --max-time 30 -d "NixOS upgrade succeeded: system changed, but no package version changes detected" "$NTFY_URL"
                else
                  curl -s --max-time 30 -d "NixOS upgrade succeeded:
                  $DIFF" "$NTFY_URL"
                fi
              fi
            fi
          '';
        in
        "${script}";
    };
  };
}
