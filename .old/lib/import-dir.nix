{ ... }:
dir:
let
  entries = builtins.readDir dir;
  names = builtins.attrNames entries;

  shouldImport =
    name:
    let
      ty = entries.${name};
      path = dir + "/${name}";
      isNixFile = builtins.match ".*\\.nix$" name != null;
    in
    name != "default.nix"
    && (
      ty == "directory"
      || (ty == "regular" && isNixFile)
      || (ty == "symlink" && (isNixFile || builtins.pathExists (path + "/default.nix")))
    );
in
builtins.map (name: import (dir + "/${name}")) (builtins.filter shouldImport names)
