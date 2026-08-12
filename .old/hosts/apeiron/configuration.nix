{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./networking.nix
    ./services.nix
  ];

  disko.enableConfig = true;
}
