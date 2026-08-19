{ lib, ... }:
let
  ipv4Type = lib.types.submodule {
    options = {
      address = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Static IPv4 address. When null the interface is configured with DHCP.";
      };

      prefixLength = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Prefix length used when a static address is set.";
      };

      gateway = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Gateway used when a static address is set. Falls back to network.gateway.";
      };
    };
  };

  interfaceType = lib.types.submodule {
    options.ipv4 = lib.mkOption {
      type = ipv4Type;
      default = { };
    };
  };

  hostOptions = {
    name = lib.mkOption {
      type = lib.types.str;
    };

    system = lib.mkOption {
      type = lib.types.str;
      default = "x86_64-linux";
    };

    network = lib.mkOption {
      type = lib.types.submodule {
        options = {
          domain = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          subnet = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.0/24";
          };

          gateway = lib.mkOption {
            type = lib.types.str;
            default = "192.168.1.1";
          };

          wifi = lib.mkOption {
            type = interfaceType;
            default = { };
            description = "IPv4 configuration for the wifi module's NetworkManager profile.";
          };

          interfaces = lib.mkOption {
            type = lib.types.attrsOf interfaceType;
            default = { };
            description = "Wired (ethernet) interfaces, keyed by kernel device name.";
          };
        };
      };
    };

    state = lib.mkOption {
      type = lib.types.submodule {
        options = {
          darwin = lib.mkOption {
            type = lib.types.int;
          };
          version = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
    };

    user = lib.mkOption {
      type = lib.types.submodule {
        options = {
          alias = lib.mkOption {
            type = lib.types.str;
            default = "alvr";
          };
          email = lib.mkOption {
            type = lib.types.str;
          };
          name = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
    };
  };
in
{
  flake.modules = {
    nixos.base.options.dot.host = hostOptions;
    darwin.base.options.dot.host = hostOptions;
    homeManager.base.options.dot.host = hostOptions;
  };
}
