{
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      virtualisation.vmVariant = {
        virtualisation.diskSize = lib.mkDefault 8192;
        virtualisation.memorySize = lib.mkDefault 4096;

        disko.enableConfig = lib.mkForce false;
        disko.devices = lib.mkForce { };

        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
        system.autoUpgrade.enable = lib.mkForce false;

        users.users.${config.dot.host.user.alias} = {
          hashedPasswordFile = lib.mkVMOverride null;
          initialPassword = config.dot.host.user.alias;
        };

        networking.networkmanager.ensureProfiles = lib.mkVMOverride { };
      };
    };
}
