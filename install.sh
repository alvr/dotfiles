#!/usr/bin/env bash
set -euo pipefail

read -rp "Flake target (e.g. .#apeiron): " flake
read -rp "Target IP/hostname: " target

if [[ -z "$flake" || -z "$target" ]]; then
  echo "Error: both the flake target and target address are required." >&2
  exit 1
fi

# Derive and validate the host name from the flake target for key handling.
host="${flake##*#}"
if [[ "$host" == "$flake" || ! "$host" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Error: flake target must end with a host name (for example .#apeiron)." >&2
  exit 1
fi

echo ""
echo "This will WIPE all disks on $target via --disko-mode disko and install $flake."
read -rp "Continue? [y/N] " confirm
if [[ "${confirm,,}" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

# Prepare extra-files directory for nixos-anywhere (provides /nix/secret/age-keys.txt on target)
EXTRA_DIR=$(mktemp -d)
trap 'rm -rf "$EXTRA_DIR"' EXIT
mkdir -p "$EXTRA_DIR/nix/secret"
chmod 700 "$EXTRA_DIR/nix" "$EXTRA_DIR/nix/secret"

AGE_KEY_FILE="$EXTRA_DIR/nix/secret/age-keys.txt"
SOURCE_AGE_KEY_FILE="${SOURCE_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

# Use an explicitly selected system key if available, otherwise generate a new one.
if [[ -s "$SOURCE_AGE_KEY_FILE" ]]; then
  echo "Found age key at $SOURCE_AGE_KEY_FILE, using it for target"
  cp "$SOURCE_AGE_KEY_FILE" "$AGE_KEY_FILE"
else
  echo "No age key found at $SOURCE_AGE_KEY_FILE, generating a new age key for host $host..."
  if ! command -v age-keygen >/dev/null 2>&1; then
    echo "Error: age-keygen not found. Install 'age' or provide $HOME/.config/sops/age/keys.txt manually." >&2
    exit 1
  fi
  age-keygen -o "$AGE_KEY_FILE"
  pubkey=$(awk '/public key:/ {print $NF}' "$AGE_KEY_FILE")
  if [[ -z "$pubkey" ]]; then
    echo "Error: age-keygen did not produce a public key." >&2
    exit 1
  fi
  echo "Generated age key. Public key: $pubkey"
  echo ""
  echo "Add the following entry to .sops.yaml under keys:"
  echo "  - &host-$host $pubkey"
  echo "And add it to the appropriate creation_rules (e.g. secrets/$host/* and secrets/common/*)"
  echo "Then run: just sops-update  # or: find secrets -type f -exec sops updatekeys -y {} \\;"
  echo ""
  read -rp "Press Enter after updating .sops.yaml, or Ctrl+C to abort..."
fi

# Allow appending additional private keys (needed to decrypt existing secrets on first install)
echo "Enter additional age private keys, one per line (end with empty line). These will be appended to age-keys.txt for sops decryption:"
while IFS= read -r line; do
  [[ -z "$line" ]] && break
  printf "%s\n" "$line" >>"$AGE_KEY_FILE"
done

chmod 400 "$AGE_KEY_FILE"
echo "Extra files prepared at $EXTRA_DIR (contains /nix/secret/age-keys.txt)"

echo ""
echo "Running nixos-anywhere..."
nix run github:nix-community/nixos-anywhere -- \
  --flake "$flake" \
  --disko-mode disko \
  --extra-files "$EXTRA_DIR" \
  "root@$target"
