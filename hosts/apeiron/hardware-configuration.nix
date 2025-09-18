{
  config,
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.kernelModules = [ "kvm-amd" ];
  boot.initrd = {
    availableKernelModules = [
      "nvme"
      "sd_mod"
      "thunderbolt"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];
  };

  fileSystems = {
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
