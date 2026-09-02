{ inputs, lib, ... }:
{
  perSystem = {
    devenv.modules = [
      inputs.devenv.flakeModules.readDevenvRoot
      {
        devenv.root = lib.mkOverride 900 inputs.self.outPath;
        containers = lib.mkForce { };
      }
    ];

    devenv.shells.default = { };
  };
}
