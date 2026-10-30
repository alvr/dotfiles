{
  flake.modules.nixos.base = {
    boot.zfs.forceImportRoot = false;
  };
}
