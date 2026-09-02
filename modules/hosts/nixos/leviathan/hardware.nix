{
  flake.modules.nixos.leviathan =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      hardware = {
        cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        graphics.enable = true;

        nvidia = {
          open = true;
          nvidiaSettings = true;
          package = pkgs.nvidia_cachyos;
        };
      };

      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
