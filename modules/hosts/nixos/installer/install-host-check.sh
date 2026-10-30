# shellcheck shell=bash
set -euo pipefail

script=$(<"${1:?installer script source path required}")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
export HOME=$work/home XDG_CONFIG_HOME=$work/config
mkdir -p "$HOME" "$XDG_CONFIG_HOME/sops/age"
unset SOPS_AGE_KEY SOPS_AGE_KEY_FILE SOPS_AGE_KEY_CMD SOPS_AGE_SSH_PRIVATE_KEY_FILE SOPS_AGE_SSH_PRIVATE_KEY_CMD
mkdir -p src/secrets/common src/secrets/box src/secrets/users/me

for k in host user stranger; do
  age-keygen -pq -o "$k.key" 2>/dev/null
done
key() { grep '^AGE-SECRET-KEY-' "$work/$1.key"; }
pub() { age-keygen -y "$work/$1.key"; }

cat >src/.sops.yaml <<EOF
keys:
  - &host-box $(pub host)
  - &user-me $(pub user)
creation_rules:
  - path_regex: secrets/(common|box)/.+
    key_groups:
      - age:
        - *host-box
  - path_regex: secrets/users/me/.+
    key_groups:
      - age:
        - *user-me
EOF

encrypt() {
  (cd src && echo 'k: v' >"$1" && sops --encrypt --in-place "$1")
}
rekey() {
  (cd src && echo 'k: v' >"$1" && sops --encrypt --age "$2" --in-place "$1")
}
encrypt secrets/common/a.yaml
encrypt secrets/box/b.yaml
encrypt secrets/users/me/c.yaml

cat >hosts.json <<EOF
{"box": {"user": "me", "home": "/home/me", "hostKeyFile": "/nix/secret/age-keys.txt", "userKeyFile": "/home/me/.config/sops/age/keys.txt", "persistRoot": null, "dotfilesDir": "/etc/nixos", "disks": []}}
EOF
export INSTALL_HOST_SRC=$work/src INSTALL_HOST_DATA=$work/hosts.json

verify() { printf '%s\n' "$@" | install-host --verify-only box; }

expect_fail() {
  local label=$1
  shift
  if verify "$@" >/dev/null 2>&1; then
    echo "install-host accepted: $label" >&2
    exit 1
  fi
}

verify "$(key user)" "$(key host)" >/dev/null
verify $' \t'"$(key user)"$' \r' "$(key host)" >/dev/null
verify $'\e[200~ \t'"$(key user)"$' \t\e[201~\r' "$(key host)" >/dev/null
expect_fail "a valid key that is not the registered user key" "$(key stranger)"
expect_fail "a valid key that is not the registered host key" "$(key user)" "$(key stranger)"
expect_fail "garbage instead of a key" "not a key"
invalid_output=$(verify "not a key" 2>&1 || true)
[[ $invalid_output == *"Try again."* ]] || {
  echo "install-host silently skipped invalid key input" >&2
  exit 1
}

rekey secrets/box/b.yaml "$(pub stranger)"
expect_fail "a host secret the host key cannot decrypt" "$(key user)" "$(key host)"

(
  export SOPS_AGE_KEY
  SOPS_AGE_KEY=$(key stranger)
  expect_fail "an unrelated key from SOPS_AGE_KEY masking a bad host recipient" "$(key user)" "$(key host)"
)
key stranger >"$XDG_CONFIG_HOME/sops/age/keys.txt"
expect_fail "an unrelated default age key masking a bad host recipient" "$(key user)" "$(key host)"
rm "$XDG_CONFIG_HOME/sops/age/keys.txt"

rekey secrets/box/b.yaml "$(pub host),$(pub stranger)"
rekey secrets/common/a.yaml "$(pub host),$(pub stranger)"
verify "$(key user)" "$(key host)" >/dev/null
expect_fail "a key that decrypts everything but is not the registered host key" "$(key user)" "$(key stranger)"

rekey secrets/box/b.yaml "$(pub host)"
rekey secrets/common/a.yaml "$(pub host)"
SOPS_AGE_KEY=$(key stranger) verify "$(key user)" "$(key host)" >/dev/null

fail() { echo "install-host check failed: $*" >&2; exit 1; }

# Relax guards only in a fixture copy; all target paths stay under the temporary root.
root=$work/root
root_guard="[[ -n \$verify_only || \$EUID -eq 0 ]]"
disk_guard="[[ -b \$disk ]]"
[[ $script == *"$root_guard"* && $script == *"$disk_guard"* ]] || fail "installer guards changed"
script=${script/"$root_guard"/true}
script=${script/"$disk_guard"/"[[ -f \$disk ]]"}
script=${script//\/mnt/$root}
printf 'set -euo pipefail\n%s\n' "$script" >"$work/install-host-test.sh"
printf '{}\n' >src/flake.nix
touch "$work/disk"

cat >"$work/disko" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo disko >>"$work/calls"
mkdir -p "$root"
EOF
chmod +x "$work/disko"

nix() {
  echo "nix $1" >>"$work/calls"
  case $1 in
    eval) [[ $FAIL_EVAL == 0 ]] ;;
    build) printf '%s\n' "$work/disko" ;;
    *) return 1 ;;
  esac
}
lsblk() {
  echo lsblk >>"$work/calls"
  [[ ${*: -1} == "$work/disk" ]]
}
install() {
  [[ ${*: -1} == "$root/"* ]] || return 1
  command install "$@"
}
chown() { echo "chown $*" >>"$work/calls"; }
nixos-install() {
  [[ $* == "--no-root-passwd --no-channel-copy --flake path:$root$expected_repo#box" &&
     -f "$root/nix/secret/age-keys.txt" &&
     -f "$root$expected_persist/home/me/.config/sops/age/keys.txt" &&
     -f "$root$expected_repo/flake.nix" ]] || return 1
  echo nixos-install >>"$work/calls"
}
export -f nix lsblk install chown nixos-install
export work root FAIL_EVAL=0

prepare_install() {
  export expected_persist=$1 expected_repo=$2
  rm -rf "$root"
  : >"$work/calls"
  jq --arg persist "$1" --arg repo "$2" --arg disk "$3" '
    .box.persistRoot = (if $persist == "" then null else $persist end) |
    .box.dotfilesDir = $repo | .box.disks = [$disk]
  ' hosts.json >install-hosts.json
  export INSTALL_HOST_DATA=$work/install-hosts.json
}
run_install() {
  printf '%s\n%s\n%s\n' "$(key user)" "$(key host)" "$1" |
    bash "$work/install-host-test.sh" box >"$work/install.log" 2>&1
}

for persist in "" /nix/persist; do
  repo=/etc/nixos
  [[ -z $persist ]] || repo=/nix/persist/dotfiles
  prepare_install "$persist" "$repo" "$work/disk"
  run_install box || { cat "$work/install.log"; fail "installation ($persist)"; }
  host_key=$root/nix/secret/age-keys.txt
  user_key=$root$persist/home/me/.config/sops/age/keys.txt
  cmp "$host_key" <(key host) || fail "host key content"
  cmp "$user_key" <(key user) || fail "user key content"
  [[ $(stat -c %a "$host_key") == 400 ]] || fail "host key permissions"
  [[ $(stat -c %a "$user_key") == 600 ]] || fail "user key permissions"
  diff -r src "$root$repo" || fail "repository copy"
  grep -Fxq "chown -R 1000:100 $root$persist/home/me" "$work/calls" || fail "user key ownership"
  grep -Fxq "chown -R 1000:100 $root$repo" "$work/calls" || fail "repository ownership"
  [[ $(grep -v '^chown ' "$work/calls") == $'nix eval\nlsblk\nnix build\ndisko\nnixos-install' ]] ||
    fail "installation order"
  if [[ -n $persist ]]; then
    [[ ! -e $root/home ]] || fail "stray user key on the impermanent root"
  fi
done

prepare_install "" /etc/nixos "$work/disk"
if run_install cancel; then fail "wrong confirmation accepted"; fi
[[ $(<"$work/calls") == $'nix eval\nlsblk' && ! -e $root ]] || fail "writes after cancellation"

prepare_install "" /etc/nixos "$work/missing-disk"
if run_install box; then fail "missing disk accepted"; fi
[[ ! -s $work/calls && ! -e $root ]] || fail "writes with a missing disk"

prepare_install "" /etc/nixos "$work/disk"
export FAIL_EVAL=1
if run_install box; then fail "failed evaluation accepted"; fi
[[ $(<"$work/calls") == "nix eval" && ! -e $root ]] || fail "writes after failed evaluation"

echo "install-host checks passed"
