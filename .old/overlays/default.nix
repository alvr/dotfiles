{ inputs, ... }:
[
  (import ./packages.nix { })
  inputs.chaotic.overlays.default
]
