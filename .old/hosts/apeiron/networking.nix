{ lib, ... }:
{
  networking = {
    hostName = "apeiron";
    useDHCP = lib.mkDefault true;
  };
}
