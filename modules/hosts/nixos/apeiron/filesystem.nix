{
  flake.modules.nixos.apeiron =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.mergerfs ];

      systemd.tmpfiles.rules = [
        "d /nix/persist/dotfiles 0755 ${config.dot.host.user.alias} users -"
      ];

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
            "nofail"
          ];
        };

        "/nix/persist".neededForBoot = true;
      };
    };
}
