{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    just
    mergerfs
    neovim
    sops
    statix
  ];
}
