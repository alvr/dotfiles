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
      systemd
      nvd
      curl
    ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          script = pkgs.writeShellScript "upgrade-notify.sh" ''
            set -uo pipefail

            NTFY_URL = $(cat ${config.sops.secrets.upgrade-notify-url.path})
            STATUS = $(systemctl is-failed nixos-upgrade.service 2 > /dev/null || echo "unknown")

            if [ "$STATUS" = "failed" ] ; then
              LOG = $(journalctl -u nixos-upgrade.service -n 50 --no-pager 2 > /dev/null || echo "No log available")
              curl -s --max-time 30 -d "NixOS upgrade failed:
              $LOG" "$NTFY_URL"
            else
              CURRENT = $(readlink /nix/var/nix/profiles/system 2 > /dev/null | sed 's/.*system-\([0-9]*\)-link.*/\1/' || echo "")
              if [ -z "$CURRENT" ] ; then
                curl -s --max-time 30 -d "NixOS upgrade succeeded: could not determine generation" "$NTFY_URL"
              else
                PREVIOUS = $((CURRENT - 1))
                if [ "$PREVIOUS" -lt 1 ] ; then
                  curl -s --max-time 30 -d "NixOS upgrade succeeded: first generation, no previous to compare" "$NTFY_URL"
                else
                  DIFF = $(nvd diff "/nix/var/nix/profiles/system-$CURRENT-link" "/nix/var/nix/profiles/system-$PREVIOUS-link" 2 > /dev/null || echo "")
                  if [ -z "$DIFF" ] ; then
                    curl -s --max-time 30 -d "NixOS upgrade succeeded: no packages updated" "$NTFY_URL"
                  else
                    curl -s --max-time 30 -d "NixOS upgrade succeeded:
                    $DIFF" "$NTFY_URL"
                  fi
                fi
              fi
            fi
          '';
        in
        "${script}";
    };
  };
}
