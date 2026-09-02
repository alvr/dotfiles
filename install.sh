#!/usr/bin/env bash
set -euo pipefail

read -rp "Flake target (e.g. .#apeiron): " flake
read -rp "Target IP/hostname: " target

nix run github:nix-community/nixos-anywhere -- \
  --flake "$flake" \
  --disko-mode disko \
  "root@$target"
