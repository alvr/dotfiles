{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos-server;
    tmp.cleanOnBoot = true;
    zfs.forceImportRoot = false;

    kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
    };

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
