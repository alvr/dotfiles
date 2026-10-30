# ❄️ Nix dotfiles

My configuration files for NixOS
Declarative NixOS and home-manager configuration for my machines, built as a single flake.

> [!NOTE]
> This is a personal configuration. It hardcodes users, SSH keys, domains and service settings, so treat it as a reference rather than a drop-in template.

## Hosts

| Host | Role | Description |
| --- | --- | --- |
| `apeiron` | Server | Self-hosted services: media, monitoring, productivity, development and security. Deployed remotely with deploy-rs. |
| `leviathan` | Desktop | Daily driver: MangoWC/Noctalia, gaming, development tooling and CLI environment. |

Both hosts run `x86_64-linux`. nix-darwin scaffolding exists in `modules/`, but no Darwin host is currently configured.

## What's inside

- **Flake-parts + import-tree** — every file under `modules/` is imported automatically and contributes `flake.modules.<class>.<name>`.
- **Roles** — `desktop` and `server` bundle the base modules, features and home-manager programs a host needs.
- **Custom `dot.host` options** — host name, network, state version and user details are declared once and consumed everywhere.
- **sops-nix with age** — per-host and per-user secrets, decrypted at activation.
- **disko** — declarative disk layouts: tmpfs root with impermanence on the server, btrfs with snapper snapshots on the desktop.
- **deploy-rs** — remote, build-on-target deployments for server hosts.
- **Catppuccin Macchiato** theming and a reproducible development shell via devenv.

## Repository layout

```
.
├── flake.nix            # inputs and flake-parts entry point
├── flake.lock
├── modules/
│   ├── base/            # shared NixOS, nix-darwin and home-manager baseline
│   ├── features/        # opt-in system features (audio, gaming, wifi, sops, …)
│   ├── hosts/           # host definitions and the dot.host option schema
│   ├── lib/             # small helper functions
│   ├── programs/        # program configuration (CLI, dev tools, WM, gaming)
│   ├── roles/           # desktop/server composition of modules
│   ├── services/        # self-hosted services used by apeiron
│   └── tools/           # flake plumbing: devenv, disko, treefmt, schemas
├── packages/            # local packages, exposed through pkgs-by-name
├── secrets/             # sops-encrypted secrets (flake input)
└── .justfile            # day-to-day commands
```

## Requirements

- Nix with flakes enabled
- `just`
- An age private key that can decrypt `secrets/` (for switching or deploying)
- [direnv](https://direnv.net/) (optional, but the repo ships an `.envrc`)

The dev shell provides `just`, `sops`, `statix`, `deploy-rs` and the formatting hooks:

```sh
direnv allow          # or: nix develop .#dev-nix
just --list
```

## Usage

| Command | Description |
| --- | --- |
| `just apply` | Build and switch the current host |
| `just apply-boot` | Build and activate on next boot |
| `just apply-dry` | Dry-run the current host configuration |
| `just apply-rollback` | Roll back to the previous system generation |
| `just deploy [group]` | Deploy to a deploy-rs group (default: `server`, built on the target) |
| `just deploy-boot [group]` | Deploy to a deploy-rs group (default: `server`), activated on next boot |
| `just deploy-bootstrap [group]` | Deploy the `bootstrap` group (default: `bootstrap`), built on the current host |
| `just deploy-dry [group]` | Dry-activate a remote deployment (default: `server`) |
| `just build-installer` | Build the NixOS installer ISO image |
| `just build-vm <host>` | Build `<host>` as a VM |
| `just up` | Update `flake.lock` |
| `just fmt` | Format with `nix fmt`, run `nix flake check --no-build`, and `statix check` |
| `just gc` | Garbage-collect the Nix store |
| `just repair` | Verify and repair the Nix store |
| `just generations` | List generations of the system profile |
| `just generations-switch <version>` | Switch to a specific system generation |
| `just sops-update` | Re-encrypt secrets for the current key set |
| `just sops-rotate` | Rotate all sops-encrypted secrets |
| `just sops-check` | Verify every secret can be decrypted |
| `just fetch [branch]` | Fetch and reset to origin/[branch] (default: `main`) |

Targets can be referenced as `.#leviathan` or `.#apeiron` (e.g. `nixos-rebuild switch --flake .#leviathan`).

> [!WARNING]
> Deployment and activation require the host's age key. On a machine without it, `just apply` will fail when sops tries to decrypt secrets.

## Installing a new host

Build and boot the installer ISO, then run the interactive `install-host` tool from inside the installer:

```sh
just build-installer
# Write result-iso/*.iso to a USB and boot the target

# On the installer:
sudo install-host
```

`install-host` will:

1. Prompt for the host to install (from `flake.nixosConfigurations`, excluding `installer`)
2. Prompt for and verify the user age key (`&user-<user>`) and host age key (`&host-<host>`) against `.sops.yaml`, and verify decryption of `secrets/users/<user>`, `secrets/common`, and `secrets/<host>`
3. Wipe and partition the disks declared in the host's disko layout
4. Copy the flake to the target, install the host keys in place, and run `nixos-install` from the copied flake

> [!CAUTION]
> The installer **wipes every disk** on the target. Double-check the flake target and host before confirming.
>
> Add the age public keys to `.sops.yaml` and re-encrypt secrets with `just sops-update` before installing if they are new.

## Secrets

Secrets live in `secrets/` and are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and age:

- Host secrets: `secrets/<host>/`
- Shared secrets: `secrets/common/`
- User secrets: `secrets/users/<user>/` (home-manager)

Host keys are read from `/nix/secret/age-keys.txt` at activation; the user key is read from `~/.config/sops/age/keys.txt` (generated on first use if missing). The key recipients and creation rules are defined in `.sops.yaml`.

> [!IMPORTANT]
> Never commit private age keys. Only the encrypted `secrets/*.yaml` files belong in the repository.

## Development

```sh
nix fmt # nixfmt via treefmt
nix flake check --no-build
statix check
```

The dev shell installs a pre-commit hook with [prek](https://github.com/j178/prek) that runs the same three checks. Flake inputs are updated automatically twice a week by a Forgejo Actions workflow (`.forgejo/workflows/update-flake.yml`), or manually with `just up`.
