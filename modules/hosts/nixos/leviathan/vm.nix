{
  flake.modules.nixos.leviathan = { lib, ... }: {
    virtualisation.vmVariant = {
      hardware.nvidia.package = lib.mkForce null;
      services.xserver.videoDrivers = lib.mkForce [ ];
    };
  };
}
