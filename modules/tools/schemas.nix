{ inputs, ... }:
{
  flake.schemas = inputs.flake-schemas.exportedSchemas // {
    deploy = {
      version = 1;
      doc = "The `deploy` flake output contains deploy-rs deployment targets.";
      inventory = output: {
        children = builtins.mapAttrs (_name: _value: {
          what = "deploy-rs node";
        }) output.nodes;
      };
    };

    diskoConfigurations = {
      version = 1;
      doc = "The `diskoConfigurations` flake output contains disk layouts for use with disko.";
      inventory = output: {
        children = builtins.mapAttrs (_name: _value: {
          forSystems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          what = "disko configuration";
        }) output;
      };
    };

    lib = {
      version = 1;
      doc = "The `lib` flake output contains helper functions for building configurations.";
      inventory = output: {
        children = builtins.mapAttrs (_name: value: {
          what = "library function";
          evalChecks.isFunction = builtins.isFunction value;
        }) output;
      };
    };

    modules = {
      version = 1;
      doc = "The `modules` flake output contains NixOS, nix-darwin and home-manager modules.";
      inventory = output: {
        children = builtins.mapAttrs (_family: modules: {
          what = "module family";
          children = builtins.mapAttrs (_name: module: {
            what = "module";
            evalChecks.isModule = builtins.isAttrs module || builtins.isFunction module;
          }) modules;
        }) output;
      };
    };
  };
}
