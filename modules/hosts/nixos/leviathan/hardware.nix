{
  flake.modules.nixos.leviathan = { config, lib, ... }: {
    hardware = {
      cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      graphics.enable = true;

      nvidia = {
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.cachyos;
      };
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
