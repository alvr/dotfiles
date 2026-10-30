# shellcheck shell=bash
src=${INSTALL_HOST_SRC:-@src@}
data=${INSTALL_HOST_DATA:-@data@}

die() {
  echo "Error: $*" >&2
  exit 1
}

verify_only=
if [[ ${1:-} == --verify-only ]]; then
  verify_only=1
  shift
fi
[[ -n $verify_only || $EUID -eq 0 ]] || die "run as root (sudo install-host)"

host=${1:-}
if [[ -z $host ]]; then
  echo "Hosts: $(jq -r 'keys | join(" ")' "$data")"
  read -rp "Host to install: " host
fi
jq -e --arg h "$host" '.[$h]' "$data" >/dev/null || die "unknown host '$host'"

get() { jq -r --arg h "$host" ".[\$h]$1 // empty" "$data"; }

user=$(get .user)
home=$(get .home)
persist=$(get .persistRoot)
host_key_file=$(get .hostKeyFile)
user_key_file=$(get .userKeyFile)
dotfiles_dir=$(get .dotfilesDir)
[[ -n $user && -n $home && -n $host_key_file && -n $user_key_file && -n $dotfiles_dir ]] || die "incomplete install data for $host"

recipient() {
  awk -v a="&$1" '$1 == "-" && $2 == a { print $3; exit }' "$src/.sops.yaml"
}

read_key() {
  local file=$1 anchor=$2 want key line
  want=$(recipient "$anchor")
  [[ -n $want ]] || die "no &$anchor in .sops.yaml: create the key, add it there and run 'just sops-update' first"
  while :; do
    echo "Paste only the age private-key line for $anchor (input is hidden), then press Enter:"
    IFS= read -rs line || die "no age private key received"
    echo
    line=${line//$'\r'/}
    line=${line//$'\e[200~'/}
    line=${line//$'\e[201~'/}
    key=${line#"${line%%[![:space:]]*}"}
    key=${key%"${key##*[![:space:]]}"}
    if [[ $key == AGE-SECRET-KEY-* ]]; then
      (umask 077 && printf '%s\n' "$key" >"$file")
      echo "Validating the $anchor key..."
      [[ $(age-keygen -y "$file" 2>/dev/null) == "$want" ]] && return 0
    fi
    echo "That is not a valid age key, or it is not the &$anchor key in .sops.yaml. Try again."
  done
}

decrypt_all() {
  local key=$1 dir file count=0
  shift
  for dir in "$@"; do
    [[ -d $dir ]] || die "missing ${dir#"$src"/}"
    echo "  Checking decryption of ${dir#"$src"/}..."
    while IFS= read -r -d '' file; do
      # Only the selected key may satisfy verification, not other age or SSH keys.
      env -i PATH="$PATH" HOME="$tmp" XDG_CONFIG_HOME="$tmp" SOPS_AGE_KEY_FILE="$key" \
        sops decrypt "$file" >/dev/null || die "cannot decrypt ${file#"$src"/}"
      count=$((count + 1))
    done < <(find "$dir" -type f -print0)
  done
  [[ $count -gt 0 ]] || die "no secrets found to check"
  echo "  decrypted $count files"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
user_key=$tmp/user.key
host_key=$tmp/host.key

echo "== User key ($user) =="
read_key "$user_key" "user-$user"
decrypt_all "$user_key" "$src/secrets/users/$user"

echo "== Host key ($host) =="
read_key "$host_key" "host-$host"
decrypt_all "$host_key" "$src/secrets/common" "$src/secrets/$host"

echo "Keys verified."
[[ -z $verify_only ]] || exit 0

mapfile -t disks < <(get '.disks[]')
[[ ${#disks[@]} -gt 0 ]] || die "no disks defined for $host"
for disk in "${disks[@]}"; do
  [[ -b $disk ]] || die "disk $disk not found (is the /dev/disk/by-id name right?)"
done

echo "== Checking that the $host configuration evaluates =="
nix eval --raw "path:$src#nixosConfigurations.$host.config.system.build.toplevel.drvPath" >/dev/null

echo "These disks will be ERASED:"
lsblk -o NAME,SIZE,MODEL,SERIAL "${disks[@]}"
read -rp "Type '$host' to erase them and install: " answer
[[ $answer == "$host" ]] || die "aborted"

echo "== Partitioning with disko =="
disko=$(nix build --no-link --print-out-paths "path:$src#nixosConfigurations.$host.config.system.build.diskoScript")
"$disko"

dotfiles=/mnt$dotfiles_dir

install -D -m 0400 "$host_key" "/mnt$host_key_file"
install -D -m 0600 "$user_key" "/mnt$persist$user_key_file"
# shortcut: assumes the user gets uid 1000 and group users (100), pin users.users.<alias>.uid if that changes
chown -R 1000:100 "/mnt$persist$home"

install -d -m 0755 "$dotfiles"
cp -a "$src/." "$dotfiles/"
chmod -R u+w "$dotfiles"
chown -R 1000:100 "$dotfiles"

echo "== Installing $host =="
nixos-install --no-root-passwd --no-channel-copy --flake "path:$dotfiles#$host"
echo "Done. Reboot into $host."
