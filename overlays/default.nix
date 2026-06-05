{ inputs, ... }:
[
  (import ./lix.nix { })
  (import ./packages.nix { })
  inputs.nix-cachyos-kernel.overlays.pinned
]
