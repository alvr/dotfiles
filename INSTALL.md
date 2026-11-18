# Installing a new machine

End-to-end guide for adding a host to this flake and installing NixOS on it. Read it fully before starting — the disk step is destructive.

## 0. Prerequisites

On the machine you work from:

- Nix with flakes enabled, plus the repo's dev shell for `just`, `sops`, `age`, `statix`:
  ```sh
  nix develop .#dev-nix   # or: nix-shell equivalent; provides just/sops/age/deploy-rs
  ```
- For a **new host**, a fresh age key pair for the host (generated in step 2).
- The **user** age private key (`user-<alias>` in `.sops.yaml`) — needed during install.
- If reusing an existing user's encrypted secrets: the ability to decrypt `secrets/users/<alias>` and `secrets/common`.

## 1. Create the host configuration

Copy the closest existing host as a template:

- `modules/hosts/nixos/leviathan/` — desktop role, single-NVMe btrfs + snapper.
- `modules/hosts/nixos/apeiron/` — server role, tmpfs root + impermanence + LVM + mergerfs.

Files to create under `modules/hosts/nixos/<host>/`:

| File | Contents |
| --- | --- |
| `configuration.nix` | `dot.host` metadata: `name`, `state.version`, `network` (domain, `ssh.port`, static IPv4 — required by the server role), `user` (email, name, `sshKeys`). |
| `default.nix` | `flake.nixosConfigurations.<host>` wiring the role, `self.diskoConfigurations.<host>`, host features/services, and the matching `home-manager.users.<alias>` role import. |
| `disko-config.nix` | `flake.diskoConfigurations.<host>` disk layout (see §4). |
| `hardware.nix` | `hardware-configuration` equivalents (kernel modules, `boot` settings, CPU/gpu). |
| `filesystem.nix`, `boot.nix` | Any extra mounts/boot tweaks the role doesn't cover. |

Server-role assertions require: a `network.domain`, at least one `user.sshKeys` entry, and a static IPv4 on wifi or a named interface.

**Commit or `git add` new module files before evaluating** — the main flake only sees tracked files (the `secrets` input is `path:./secrets` and `flake = false`, so its untracked files are visible, but `self` is not).

## 2. Age keys and `.sops.yaml`

Each host decrypts with its **host key** (`sops.age.keyFile = /nix/secret/age-keys.txt`); each user decrypts Home-Manager secrets with a **user key** (`~/.config/sops/age/keys.txt`).

1. Generate the host key:
   ```sh
   age-keygen -o host-<host>.txt
   age-keygen -y host-<host>.txt   # public key
   ```
   Keep the private key safe — you will paste it into the installer (it's never stored in the repo).
2. In `.sops.yaml`:
   - Add the public key to `keys:` as `- &host-<host> age1...`.
   - Add a creation rule so `secrets/<host>/**` encrypts to `*host-<host>`.
   - `secrets/common/**` must include **every** host key (it's shared: user passwords, wifi, etc.).
   - `secrets/users/<alias>/**` encrypts to `*user-<alias>` only.
3. If you added a host key to `common` recipients, re-encrypt the affected files:
   ```sh
   just sops-update    # sops updatekeys on every file under secrets/
   ```

## 3. Create / encrypt secrets

Layout:

```
secrets/<host>/secrets.yaml        # host-level secrets (default sops file)
secrets/<host>/services/*.yaml     # per-service secrets (explicit sopsFile)
secrets/common/*.yaml              # shared (user-passwords.yaml holds login hashes)
secrets/users/<alias>/secrets.yaml # Home Manager secrets (user key)
```

Required for a working first boot:

- `secrets/common/user-passwords.yaml`: key `<user-alias>` with the login password hash (`mkpasswd -m yescrypt`).
- `secrets/<host>/secrets.yaml`: whatever the enabled modules declare without an explicit `sopsFile` — e.g. `tailscale-authkey` if `tailscale` is imported.
- `secrets/users/<alias>/secrets.yaml`: only if HM modules need it; the file must exist if referenced.
- `secrets/<host>/services/<service>.yaml`: one per enabled service that declares `sopsFile` secrets. Check `grep -rn 'secrets/' modules/services/<category>/<service>.nix`.

Encrypt new files **from the repo root** so `.sops.yaml` rules apply:

```sh
sops secrets/<host>/secrets.yaml            # creates encrypted in place on save
just sops-check                             # verifies every file decrypts (needs all keys)
```

## 4. Disks: verify, then partition/format (disko)

Disk layout is fully declarative in `disko-config.nix` and the install **erases every disk listed there**.

1. Identify devices on the target machine (run from any live system):
   ```sh
   lsblk -o NAME,SIZE,MODEL,SERIAL
   ls -l /dev/disk/by-id/
   ```
   **Always use `/dev/disk/by-id/...` paths**, never `/dev/sdX` — enumeration order changes between boots.
2. Write `flake.diskoConfigurations.<host>` to match. Existing layouts:
   - `leviathan`: GPT → EFI + btrfs subvolumes (`@`, `@nix`, `@home`, `@/.snapshots`, …) + snapper.
   - `apeiron`: `tmpfs` root, EFI + LVM PV per disk, VGs for `/nix`, `/nix/persist` and the mergerfs `/data` pool.
3. Sanity checks before booting the installer:
   ```sh
   nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
   just build-vm <host>     # optional: boots the host config in a VM
   ```

## 5. Build the installer ISO

```sh
just build-installer      # → result-iso/… .iso
sudo dd if=result-iso/iso/*.iso of=/dev/<usb> bs=4M status=progress oflag=sync
```

The ISO is a minimal image with `install-host` baked in — including **a copy of the repo at build time** (`${self}`). Rebuild the ISO after changing host config, or override at runtime with `INSTALL_HOST_SRC=/path/to/checkout`.

The installer sets a known root password and enables SSH (`PermitRootLogin yes`, password auth) — you can `ssh root@<installer-ip>` and do the whole install remotely.

## 6. Run the install

On the booted installer:

```sh
install-host --verify-only <host>   # dry run: checks keys + secret decryption only
sudo install-host <host>
```

The script will:

1. Ask you to paste the **user** and **host** age private keys (hidden input) and verify each against `.sops.yaml` — a valid but unregistered key is rejected.
2. Try to decrypt `secrets/users/<alias>` (user key) and `secrets/common` + `secrets/<host>` (host key); it aborts on any file the key can't open.
3. Check every `disko` device exists as a block device.
4. Evaluate `nixosConfigurations.<host>` toplevel — nothing is written before this passes.
5. Show `lsblk` for the target disks and require you to type the hostname to confirm.
6. Run the disko script, then:
   - install the host key → `/mnt/nix/secret/age-keys.txt` (mode 400)
   - install the user key → `/mnt/<persist>/home/<user>/.config/sops/age/keys.txt` (mode 600)
   - copy the repo → `/mnt/<dotfilesDir>` (`/etc/nixos`, or the persisted path on impermanence hosts) owned by uid 1000
7. `nixos-install --no-root-passwd --no-channel-copy --flake path:<repo>#<host>`.

## 7. First boot & verification

- Log in as the user (password from `secrets/common/user-passwords.yaml`) or via SSH key.
- Disks/mounts:
  ```sh
  findmnt          # all expected mounts present
  lsblk -f         # filesystems/labels match the disko layout
  ```
  Impermanence hosts: confirm `/nix/persist` (and `/data` mergerfs pool) are mounted; check `systemctl status` for failed mount units.
- Secrets: `ls /run/secrets` (system) and `systemctl --user status sops-nix` (HM); a wrong/missing age key shows up as sops-nix activation failures.
- On **server/deployable hosts**: the first `nixos-rebuild` may need to run locally before `just deploy` works (check the deploy notes for the current SSH/root state).
- Desktop hosts apply locally with `just apply`; servers remotely with `just deploy` / `just deploy-bootstrap`.

## 8. Key rotation

- **Rotate the data-encryption keys** (re-encrypts every file with a fresh data key, same recipients):
  ```sh
  just sops-rotate
  ```
- **Rotate an age identity** (host key compromised, new machine key, etc.):
  1. `age-keygen` a new pair; swap the public key in `.sops.yaml`.
  2. `just sops-update` to add the new recipient — do this **before** removing the old key so old files stay decryptable.
  3. Remove the old anchor once everything is re-keyed, then `just sops-update` again.
  4. Copy the new private key to the host's `/nix/secret/age-keys.txt` (and the user's `~/.config/sops/age/keys.txt` if it was a user key).
- After any `.sops.yaml` change: `just sops-check` to prove nothing is orphaned. A file whose recipients no longer include a live key is unrecoverable — `.sops.yaml` anchors are the only record the installer validates against.

## 9. Gotchas

- **`install-host` assumes uid 1000 / gid 100** for the copied repo and user key — pin `users.users.<alias>.uid` if that ever changes.
- The repo copy on the target comes from the ISO build; re-clone/pull after first boot so `/etc/nixos` (or the persisted dotfiles dir) is current.
- `just sops-check` fails if you don't hold **all** keys (host keys included) — that's expected; `install-host --verify-only` checks the relevant subset with each key separately.
- Don't commit decrypted secrets; every file under `secrets/` must stay sops-encrypted.
- `just fetch` does `git reset --hard` — don't run it with uncommitted work.
