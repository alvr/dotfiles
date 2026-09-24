{
  inputs,
  lib,
  self,
  ...
}:
{
  perSystem = {
    devenv.modules = [
      inputs.devenv.flakeModules.readDevenvRoot
      {
        devenv.root = lib.mkOverride 900 self.outPath;
        containers = lib.mkForce { };
      }
    ];

    devenv.shells.default = { };
  };
}
