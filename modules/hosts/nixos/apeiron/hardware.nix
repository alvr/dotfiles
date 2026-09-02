{
  flake.modules.nixos.apeiron =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      hardware = {
        enableRedistributableFirmware = lib.mkDefault true;
        cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            libva
            libvdpau-va-gl
            libva-vdpau-driver
          ];
        };
      };

      services.xserver.videoDrivers = [ "amdgpu" ];
    };
}
