{
  flake.modules.nixos.leviathan = { pkgs, ... }: {
    stylix.targets.limine.enable = true;

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

        limine = {
          enable = true;
          enableEditor = false;
          maxGenerations = 10;
          resolution = "2560x1440x32";

          additionalFiles = {
            "efi/memtest86/memtest86.efi" = "${pkgs.memtest86-efi}/BOOTX64.EFI";
          };

          extraEntries = ''
            /MemTest86
              protocol: chainload
              path: boot():///efi/memtest86/memtest86.efi
          '';
        };
      };
    };
  };
}
