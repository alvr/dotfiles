{ inputs }:
let
  overlaysDir = ./.;

  overlayFiles = builtins.filter (
    name: name != "default.nix" && builtins.match ".*\\.nix" name != null
  ) (builtins.attrNames (builtins.readDir overlaysDir));

  importOverlay = name: import (overlaysDir + "/${name}") { inherit inputs; };
in
map importOverlay overlayFiles
