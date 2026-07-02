{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-server;
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
