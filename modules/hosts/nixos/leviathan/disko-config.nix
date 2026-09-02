{ inputs, ... }:
{
  flake.diskoConfigurations.leviathan = {
    imports = [
      inputs.disko.nixosModules.disko
    ];

    disko.enableConfig = true;

    disko.devices = {
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=8G"
          "mode=755"
        ];
      };
    };
  };
}
