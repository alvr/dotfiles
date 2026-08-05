{ inputs, ... }:
[
  (import ./lix.nix { })
  (import ./packages.nix { })
  inputs.chaotic.overlays.default
]
