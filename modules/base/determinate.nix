{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.determinate.nixosModules.default ];
  };

  flake.modules.darwin.base = {
    imports = [ inputs.determinate.darwinModules.default ];
    nix.enable = false;
  };
}
