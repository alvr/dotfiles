{ lib, self, ... }:
let
  hosts = lib.filterAttrs (name: _: name != "installer") self.nixosConfigurations;
in
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks =
        lib.mapAttrs' (
          name: host:
          lib.nameValuePair "host-${name}" (
            pkgs.writeText "host-${name}" (
              builtins.unsafeDiscardStringContext host.config.system.build.toplevel.drvPath
            )
          )
        ) hosts
        // lib.optionalAttrs (system == "x86_64-linux") {
          vm-config =
            assert lib.all (host: !host.config.virtualisation.vmVariant.system.autoUpgrade.enable) (
              lib.attrValues hosts
            );
            pkgs.runCommand "vm-config-check" { } "touch $out";
        };
    };
}
