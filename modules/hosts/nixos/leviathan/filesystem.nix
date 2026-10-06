{
  flake.modules.nixos.leviathan =
    { config, pkgs, ... }:
    {
      boot.initrd.supportedFilesystems = [ "btrfs" ];
      boot.tmp.useTmpfs = true;
      environment.systemPackages = [ pkgs.btrfs-assistant ];
      zramSwap.enable = true;

      services.snapper = {
        snapshotRootOnBoot = true;

        configs.root = {
          SUBVOLUME = "/";
          ALLOW_USERS = [ config.dot.host.user.alias ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          NUMBER_CLEANUP = true;
          NUMBER_LIMIT = "30";
        };

        configs.home = {
          SUBVOLUME = "/home";
          ALLOW_USERS = [ config.dot.host.user.alias ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          NUMBER_CLEANUP = true;
          NUMBER_LIMIT = "30";
        };
      };

      systemd.tmpfiles.rules = [
        "d /.snapshots 0750 root root -"
        "d /home/.snapshots 0750 root root -"
      ];

      system.activationScripts.snapper-pre-rebuild = ''
        if [ "''${NIXOS_ACTION:-}" = "switch" ]; then
          if ${pkgs.util-linux}/bin/findmnt --noheadings --output FSTYPE / |
            ${pkgs.gnugrep}/bin/grep -q btrfs; then
            echo "snapper: creating pre-rebuild snapshot of /"
            ${pkgs.snapper}/bin/snapper --config root create \
              --cleanup-algorithm number \
              --description "pre nixos-rebuild ${config.system.nixos.version}"
          fi
        fi
      '';

      fileSystems = {
        "/mnt/Multimedia" = {
          device = "UUID=5c245c0a-75f4-45cd-b899-0fa0a55382f2";
          fsType = "ext4";
          options = [ "nofail" ];
        };

        "/mnt/Development" = {
          device = "UUID=8b576b2d-8727-4068-a661-82b718c5669a";
          fsType = "ext4";
          options = [ "nofail" ];
        };

        "/mnt/Juegos" = {
          device = "UUID=276e7876-9cba-4612-ac50-a92a2a55a170";
          fsType = "xfs";
          options = [
            "defaults"
            "nofail"
          ];
        };
      };

      services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
      };
    };
}
