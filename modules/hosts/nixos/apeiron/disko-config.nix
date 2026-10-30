{ inputs, ... }:
{
  flake.diskoConfigurations.apeiron = {
    imports = [
      inputs.disko.nixosModules.disko
    ];

    disko.enableConfig = true;

    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=8G"
          "mode=755"
        ];
      };

      disk = {
        nvme0 = {
          device = "/dev/disk/by-id/nvme-FORESEE_XP1000F001T_QAA567Q000122";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                  extraArgs = [
                    "-n"
                    "boot"
                  ];
                };
              };
              lvm = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "system-vg";
                };
              };
            };
          };
        };

        nvme1 = {
          device = "/dev/disk/by-id/nvme-WD_PC_SN560_SDDPNQE-1T00-1006_22200A640806";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              lvm = {
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "data-vg";
                };
              };
            };
          };
        };
      };

      lvm_vg = {
        system-vg = {
          type = "lvm_vg";
          lvs = {
            nix = {
              size = "100G";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
                extraArgs = [
                  "-L"
                  "nix"
                ];
              };
            };
            nix-persist = {
              size = "20G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix/persist";
                mountOptions = [ "noatime" ];
                extraArgs = [
                  "-L"
                  "nix-persist"
                ];
              };
            };
            storage-primary = {
              size = "100%FREE";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/storage/primary";
                mountOptions = [ "noatime" ];
                extraArgs = [
                  "-L"
                  "storage-primary"
                ];
              };
            };
          };
        };

        data-vg = {
          type = "lvm_vg";
          lvs = {
            storage-secondary = {
              size = "100%FREE";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/storage/secondary";
                mountOptions = [ "noatime" ];
                extraArgs = [
                  "-L"
                  "storage-secondary"
                ];
              };
            };
          };
        };
      };
    };
  };
}
