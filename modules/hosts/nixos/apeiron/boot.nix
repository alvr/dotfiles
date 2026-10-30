{
  flake.modules.nixos.apeiron = { pkgs, ... }: {
    boot = {
      initrd.availableKernelModules = [
        "nvme"
        "sd_mod"
        "thunderbolt"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      kernelPackages = pkgs.linuxPackages_cachyos-server;
      kernelModules = [ "kvm-amd" ];

      kernel.sysctl = {
        "kernel.kptr_restrict" = 2;
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
      };

      loader = {
        efi.canTouchEfiVariables = true;
        timeout = 5;

        systemd-boot = {
          enable = true;
          configurationLimit = 10;
        };
      };

      tmp.cleanOnBoot = true;
    };
  };
}
