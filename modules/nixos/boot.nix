{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-server-lto;
    tmp.cleanOnBoot = true;
    zfs.forceImportRoot = false;

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
