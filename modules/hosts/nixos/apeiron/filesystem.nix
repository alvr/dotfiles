{
  flake.modules.nixos.apeiron = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.mergerfs ];

    fileSystems = {
      "/data" = {
        fsType = "fuse.mergerfs";
        device = "/storage/*";
        options = [
          "defaults"
          "allow_other"
          "use_ino"
          "cache.files=partial"
          "dropcacheonclose=true"
          "category.create=msppfrd"
        ];
      };

      "/etc/nixos" = {
        device = "/nix/persist/dotfiles";
        fsType = "none";
        options = [
          "bind"
          "ro"
        ];
      };

      "/nix/persist".neededForBoot = true;
    };
  };
}
