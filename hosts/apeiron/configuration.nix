{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./networking.nix
  ];

  disko.enableConfig = true;
}
