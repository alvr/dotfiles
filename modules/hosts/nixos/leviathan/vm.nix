{
  flake.modules.nixos.leviathan =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      virtualisation.vmVariant = {
        virtualisation.diskSize = 8192;
        virtualisation.memorySize = 4096;

        disko.enableConfig = lib.mkForce false;
        disko.devices = lib.mkForce { };

        fileSystems."/" = lib.mkVMOverride {
          device = "/dev/vda";
          fsType = "ext4";
        };

        hardware.nvidia.package = lib.mkForce null;
        services.xserver.videoDrivers = lib.mkForce [ ];

        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

        users.users.${config.dot.host.user.alias} = {
          hashedPasswordFile = lib.mkVMOverride null;
          initialPassword = config.dot.host.user.alias;
        };

        networking.networkmanager.ensureProfiles = lib.mkVMOverride { };
      };
    };
}
