{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    kernelModules = [ "kvm-amd" ];
    zfs.forceImportRoot = false;
    initrd = {
      availableKernelModules = [
        "nvme"
        "sd_mod"
        "thunderbolt"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
    };
  };

  fileSystems = {
    "/data" = {
      fsType = "fuse.mergerfs";
      device = "/storage/*";
      options = [
        "defaults"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=msppfrd"
      ];
    };

    "/etc/nixos" = {
      device = "/nix/persist/dotfiles";
      fsType = "none";
      options = [
        "bind"
        "ro"
      ];
    };

    "/nix/persist".neededForBoot = true;

    "/var/log" = {
      device = "/nix/persist/var/log";
      fsType = "none";
      options = [
        "bind"
        "o"
      ];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
