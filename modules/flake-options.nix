{ flake-parts-lib, lib, ... }:
{
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    darwinConfigurations = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };

    deploy = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
        options.nodes = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
          default = { };
        };
      };
      default = { };
    };

    lib = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
}
