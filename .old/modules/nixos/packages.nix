{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    just
    mergerfs
    sops
    statix
  ];
}
