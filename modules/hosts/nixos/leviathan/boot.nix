{
  flake.modules.nixos.leviathan = { pkgs, ... }: {
    boot = {
      initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;
      kernelModules = [ "kvm-amd" ];

      loader = {
        efi.canTouchEfiVariables = true;
        timeout = 5;

        # TODO: configure limine
        limine = {
          enable = true;
          maxGenerations = 10;
        };
      };
    };
  };
}
