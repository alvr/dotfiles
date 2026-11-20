{
  flake.modules.nixos.leviathan =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      boot.kernelParams = [ "amd_pstate=active" ];

      hardware = {
        enableRedistributableFirmware = lib.mkDefault true;
        cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            libva
            nvidia-vaapi-driver
          ];
        };

        nvidia = {
          open = true;
          nvidiaSettings = true;
          powerManagement.enable = true;
          package = config.boot.kernelPackages.nvidiaPackages.cachyos;
        };
      };

      services = {
        xserver.videoDrivers = [ "nvidia" ];

        udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{power/wakeup}="disabled"
          ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x0c0330", ATTR{power/wakeup}="disabled"
        '';
      };
    };
}
