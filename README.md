# ❄️ Nix dotfiles

Declarative NixOS and Home Manager configuration for my machines, built as a single flake.

> [!NOTE]
> This is a personal configuration. It hardcodes users, SSH keys, domains, and service settings, so treat it as a reference rather than a drop-in template.

## What's inside

- **Flake-parts + import-tree** — discovers the flake modules under `modules/`; these declare reusable `flake.modules.<class>.<name>` definitions, concrete host outputs, libraries, and per-system tools. Discovery registers modules; explicit imports decide which run on a host.
- **One file per concept** — related `flake.modules.nixos.*`, `darwin.*`, and `homeManager.*` fragments live together where applicable, keeping system and user configuration aligned without requiring every concept to support all three classes.
- **Roles** — `desktop` and `server` bundle the baseline modules, features, and programs a machine archetype needs.
- **Custom `dot.host` options** — host name, network topology, state version, and user details are declared once in `modules/hosts/options.nix` and consumed across system, service, and user modules.
- **sops-nix with age** — per-host, shared, and per-user secrets decrypted at activation.
- **disko** — declarative disk layouts: `tmpfs` root with `impermanence` and `mergerfs` storage pooling on the server; `btrfs` subvolumes with `snapper` snapshots on the desktop.
- **deploy-rs** — remote, build-on-target deployments for server hosts.

## Architecture & Topology

```
flake.nix (inputs + flake-parts)
  └── import-tree ./modules
        ├── modules/hosts/options.nix   ──► defines options.dot.host.{name,system,network,state,user}
        ├── modules/base/               ──► flake.modules.{nixos,darwin,homeManager}.base
        ├── modules/features/           ──► opt-in capabilities (audio, bootvine, oo7, sops, theming, wifi, …)
        ├── modules/programs/<category> ──► co-located NixOS + Darwin + Home Manager program modules
        ├── modules/services/<category> ──► self-hosted server workloads (nginx, cloudflared, jellyfin, …)
        ├── modules/roles/{desktop,server}
        │     ├── imports base + archetype features + core program categories
        │     └── wires both NixOS system modules and Home Manager user modules
        └── modules/hosts/nixos/<host>
              ├── sets dot.host metadata + self.diskoConfigurations.<host>
              ├── imports role (desktop or server) + host-specific features/programs/services
              └── exports flake.nixosConfigurations.<host> (+ flake.deploy.nodes.<host>)
```

The flake exposes per-system tooling for `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`; this is not a list of configured machines. Both machine outputs are NixOS on `x86_64-linux`.

### Component relationships

| Layer | Path | Responsibility & Wiring |
| --- | --- | --- |
| **Entrypoint** | `flake.nix`, `modules/flake-parts.nix`, `modules/flake-options.nix` | Declares flake inputs and invokes `flake-parts.lib.mkFlake` with `inputs.import-tree ./modules` so every module file is discovered automatically without manual import lists. |
| **Host Schema (`dot.host`)** | `modules/hosts/options.nix` | Exposes `options.dot.host` (`name`, `system`, `network`, `state`, `user`) across `nixos.base`, `darwin.base`, and `homeManager.base`. Populated once per host and referenced as `config.dot.host.*` everywhere else. |
| **Base (`base`)** | `modules/base/` | Shared system and user foundation (`boot`, `determinate`, `home-manager`, `i18n`, `networking`, `nix`, `nixpkgs`, `security`, `state-version`, `vm`). Imported by every role. |
| **Features (`features`)** | `modules/features/` | Opt-in system/user capabilities (`audio`, `bluetooth`, `bootvine`, `deployable`, `fail2ban`, `impermanence`, `nextdns`, `oo7`, `openssh`, `podman`, `printing`, `sops`, `theming`, `wifi`). |
| **Programs (`programs`)** | `modules/programs/<category>/` | One file per application (co-locating `nixos`, `darwin`, and `homeManager` blocks) plus a `<category>/default.nix` aggregator so hosts and roles can import either a full category or a single program. |
| **Services (`services`)** | `modules/services/<category>/` | Self-hosted NixOS modules grouped by domain; wired into server hosts and parameterized via `config.dot.host.network.domain` and `sops-nix` secrets. |
| **Roles (`roles`)** | `modules/roles/{desktop,server}/` | Composes `base`, archetype features, and default program sets for both `flake.modules.nixos.<role>` and `flake.modules.homeManager.<role>`, plus server assertions and auto-upgrade policies. |
| **Hosts (`hosts`)** | `modules/hosts/nixos/<host>/` | Binds a role, a `disko` layout, `dot.host` settings, hardware/filesystem specifics, and host-only modules into `flake.nixosConfigurations.<host>`. |

Host metadata is set in each host's `configuration.nix`. `modules/hosts/options.nix` declares the schema; networking, users, state-version settings, services, and deployment consume it. `homeManager.base` copies `osConfig.dot.host` into the user configuration, while each host explicitly attaches its matching Home Manager role.

Files such as a host's `boot.nix`, `filesystem.nix`, and `hardware.nix` contribute to the same named module through flake-parts merging; they do not need a directory-level import list. Likewise, the server role's sibling modules add activation notifications and auto-upgrades. Service modules are selected separately in `apeiron/default.nix`, not implicitly by the `server` role.

The `deployable` feature tags a configuration for automatic inclusion in `flake.deploy.nodes`. It derives the address and SSH settings from `dot.host` (connecting as `root` via key-only auth), with a remote-build `system` profile (`server` group) and a local-build `bootstrap` profile (`bootstrap` group). The server role asserts that a domain, SSH keys, and a static IPv4 address are configured.

AI tooling shares one definition across harnesses (`modules/programs/ai/`): `mcp.nix` declares all MCP servers once via Home Manager's `programs.mcp` registry — OpenCode consumes it natively, Pi through a generated `~/.pi/agent/mcp.json`. `skills.nix` auto-discovers every flake input named `skills-*` (e.g. `skills-android`, `skills-ponytail`), builds them with `agent-skills-nix`, and installs them under `~/.agents/skills/<source>/` for any agent that reads the shared directory. Adding a harness or skill source is an adapter/input, not a duplicate config.

## Hosts

| Host | Role | System | Boot & Storage | Description |
| --- | --- | --- | --- | --- |
| `apeiron` | `server` | `x86_64-linux` | `systemd-boot` (`cachyos-server`), `disko` `tmpfs` `/` + `impermanence` + dual-NVMe LVM (`mergerfs` `/data`) | Self-hosted services across automation, networking, databases, development, media, monitoring, productivity, and security. Deployed remotely with `deploy-rs`. |
| `leviathan` | `desktop` | `x86_64-linux` | `limine` (`cachyos-lto-znver4`), `disko` `btrfs` subvolumes + `snapper` snapshots | Daily driver workstation: Umbriel/Noctalia Wayland desktop, gaming, AI, development tooling, and CLI environment. |

Both active hosts run `x86_64-linux`. `nix-darwin` module scaffolding exists across `modules/`, and an `installer` ISO configuration lives under `modules/hosts/nixos/installer/`, though no Darwin host is currently configured.

### `apeiron` (Server)

Defined in `modules/hosts/nixos/apeiron/` (`default.nix`, `configuration.nix`, `disko-config.nix`, `filesystem.nix`, `boot.nix`, `hardware.nix`, `jellyfin-apeiron.nix`).

- **Inherited from `server` role (`modules/roles/server/`)**:
  - **NixOS**: `base`, `bootvine`, `deployable`, `fail2ban`, `impermanence`, `nextdns`, `openssh`, `sops`, `cli`, plus unattended `auto-upgrade`, `activation`, and `upgrade-notify` units
  - **Home Manager**: `base`, `impermanence`, `sops`, `cli`, `direnv`, `git`
- **Theming**: none — servers are reached over SSH, so `stylix` is not imported and the CLI programs keep their default palettes (`btop`/`fzf`/`fish`/`starship`/`lazygit` follow the terminal's ANSI colors).
- **Host-specific features**: `podman`, `wifi`
- **Storage & deployment**: dual-NVMe LVM, an 8 GiB `tmpfs` root, Btrfs `/nix`, ext4 `/nix/persist`, and ext4 storage volumes pooled at `/data` with `mergerfs`. `/etc/nixos` is a read-only bind mount of `/nix/persist/dotfiles`. Uses `deploy-rs` (`system` or `bootstrap` profile).
- **Hardware**: AMD CPU and AMD graphics; host-specific Jellyfin acceleration settings live in `jellyfin-apeiron.nix`.
- **Self-hosted services (`modules/services/`)**:
  - **Automation**: `home-assistant`
  - **Core**: `cloudflared`, `duckdns`, `nginx`, `restic`, `tailscale`
  - **Databases**: `couchdb`, `postgresql` *(a `mariadb` module also exists in `modules/services/databases/`)*
  - **Development**: `forgejo`, `wakapi`
  - **Media**: `bazarr`, `bookorbit`, `flaresolverr`, `jackett`, `jellyfin` (+ `jellyfin-apeiron`), `radarr`, `rtorrent`, `seerr`, `sonarr`
  - **Monitoring**: `grafana`, `prometheus`, `umami`, `uptime-kuma`
  - **Productivity**: `actual-budget`, `miniflux`, `nextcloud`, `papra`, `readeck`
  - **Security**: `pocket-id`, `vaultwarden`

### `leviathan` (Desktop)

Defined in `modules/hosts/nixos/leviathan/` (`default.nix`, `configuration.nix`, `disko-config.nix`, `filesystem.nix`, `boot.nix`, `hardware.nix`, `vm.nix`).

- **Inherited from `desktop` role (`modules/roles/desktop/`)**:
  - **NixOS baseline & features**: `base`, `audio`, `bluetooth`, `bootvine`, `nextdns`, `oo7`, `printing`, `sops`, `theming` (Stylix `autoEnable = false`)
  - **Shared program categories (NixOS + Home Manager)**: `ai`, `cli`, `development`, `messaging`, `productivity`, `window-manager`
  - **System-only program categories**: `gaming`, `hardware`, `vpn`
  - **Home Manager baseline & features**: `base`, `sops`, `theming`
- **Host-specific features**: `wifi`; program categories are inherited from the role, not added by this host.
- **Theming**: Noctalia drives desktop theming by default, while `theming` wires Stylix (`autoEnable = false`) to style targets without Noctalia templates or with Home Manager-managed configs (`limine`, `starship`, `lazygit`, `jjui`, `mpv`, `ncspot`), and pushes the Stylix fonts into fontconfig, GTK and `kdeglobals`.
- **Credentials**: `oo7` provides a PAM-unlocked `org.freedesktop.secrets` keyring (`login` and `greetd`) for `bitwarden-desktop`, Noctalia, and `gitFull` (`libsecret`), while `rbw` (using `pinentry-qt`) and `bitwarden-desktop` authenticate to `https://vault.alvr.dev` over OIDC SSO (`SSO_ONLY = true`).
- **Storage & deployment**: single-NVMe Btrfs subvolumes, root/home Snapper snapshots, monthly Btrfs scrubbing, and additional ext4/XFS data mounts. Rebuilt locally with `just apply`; no deploy-rs node is configured.
- **Hardware**: AMD CPU and NVIDIA open driver (`nvidia_cachyos`); the VM variant removes the NVIDIA driver.
- **Enabled program categories (`modules/programs/`, combined system/user inventory)**:
  - **Window Manager (`window-manager`)**: `umbriel`, `noctalia`, `noctalia-greeter`, `vicinae`, and `file-manager` (Dolphin, Ark, PhotoQt)
  - **CLI (`cli`)**: `fish`, `starship`, `yazi`, `zoxide`, `fzf`, `ripgrep`, `fd`, `eza`, `bat`, `delta`, `btop`
  - **Development (`development`)**: `git`, `jujutsu`, `gh`, `direnv`, `nvchad`, `zed`, `vscodium`, `jetbrains-toolbox`, `jadx`
  - **AI (`ai`)**: `opencode` (system + HM), `pi` and `herdr`, plus the shared `ai-mcp`/`ai-skills` Home Manager modules
  - **Productivity (`productivity`)**: `ghostty`, `zen-browser`, `helium-browser`, `obsidian`, `bitwarden`, `betterbird`, `mpv`, `music`, `transmission`, `nextcloud-client`, `obs-studio`, `x-craft`. `autofirma` exists but is excluded from the category imports because of a stale dependency hash.
  - **Gaming (`gaming`)**: `steam`, `gaming-clients`, `amethyst`, `azahar`, `ryubing`, `hytale`, `coolercontrol`, `goverlay`, `openrgb`
  - **Messaging (`messaging`)**: `equibop` (Discord client), `telegram`, `whatsapp`
  - **Hardware (`hardware`)**: `fwupd`, `openlogi`
  - **VPN (`vpn`)**: `cloudflare-warp`, `tailscale-client`

## Repository layout

```
.
├── flake.nix            # inputs and flake-parts entry point
├── flake.lock
├── modules/
│   ├── flake-parts.nix  # flake-parts modules, systems, and perSystem pkgs
│   ├── flake-options.nix # flake-level darwinConfigurations, deploy, and lib options
│   ├── base/            # shared NixOS, nix-darwin, and Home Manager baseline
│   ├── features/        # opt-in system features (audio, bluetooth, wifi, sops, …)
│   ├── hosts/
│   │   ├── checks.nix   # host evaluation checks and vm-config assertions
│   │   ├── options.nix  # shared dot.host schema
│   │   ├── users.nix    # system/user identity wiring
│   │   └── nixos/
│   │       ├── apeiron/ # server composition, disks, hardware, Jellyfin overrides
│   │       ├── leviathan/ # desktop composition, disks, hardware, VM overrides
│   │       └── installer/ # ISO, install-host script, and verification script
│   ├── lib/             # helper functions (cloudflare, impermanence, networking)
│   ├── programs/        # program configuration, one file per program
│   │   ├── ai/          # OpenCode, Pi, Herdr + shared MCP servers and agent skills
│   │   ├── cli/         # Fish, Starship, Yazi, Zoxide, Fzf, Ripgrep, Bat, Btop, …
│   │   ├── development/ # Git, Jujutsu, NvChad, Zed, VSCodium, JetBrains Toolbox, …
│   │   ├── gaming/      # Steam, emulators, CoolerControl, OpenRGB
│   │   ├── hardware/    # fwupd and Logitech device tooling
│   │   ├── messaging/   # Equibop, Telegram, and WhatsApp
│   │   ├── productivity/ # desktop applications and user integrations
│   │   ├── vpn/         # Cloudflare WARP and Tailscale client
│   │   └── window-manager/ # Umbriel, Noctalia, Vicinae, file-manager
│   ├── roles/
│   │   ├── desktop/     # shared and system-only desktop bundles
│   │   └── server/      # server baseline, assertions, upgrades, notifications
│   ├── services/
│   │   ├── automation/
│   │   ├── core/
│   │   ├── databases/
│   │   ├── development/
│   │   ├── media/
│   │   ├── monitoring/
│   │   ├── productivity/
│   │   └── security/
│   └── tools/           # disko, pkgs-by-name, treefmt, schemas
│       └── shells/      # dev-nix development shell
├── packages/            # pkgs-by-name input; currently only .gitkeep, no local packages
├── secrets/             # sops-encrypted secrets (flake input)
│   ├── apeiron/
│   │   └── services/    # service-specific encrypted files
│   ├── common/
│   ├── leviathan/
│   └── users/
│       └── alvr/
├── wallpapers/          # desktop wallpapers (flake input)
├── .sops.yaml           # sops age key recipients and creation rules
└── .justfile            # day-to-day commands
```

## Requirements

- Nix with flakes enabled
- `just`
- An age private key that can decrypt `secrets/` (for switching or deploying)
- [direnv](https://direnv.net/) (optional, but the repo ships an `.envrc`)

The dev shell provides `just`, `sops`, `statix`, `deploy-rs`, and the formatting hooks:

```sh
direnv allow          # or: nix develop .#dev-nix
just --list
```

## Usage

Recipe signatures below preserve the arguments and defaults from `.justfile`; descriptions reproduce its `[doc(...)]` text (including template placeholders). `default` has no annotation.

| Command | Description |
| --- | --- |
| `just` / `just default` | List available recipes (`just --list`) |
| `just apply` | Apply configuration on current host |
| `just apply-boot` | Apply configuration on current host, activated on boot |
| `just apply-dry` | Dry test configuration on current host |
| `just apply-rollback` | Rollback to previous configuration on current host |
| `just deploy groups='server'` | Deploy configuration to {{ groups }} (built on remote host) |
| `just deploy-boot groups='server'` | Deploy configuration to {{ groups }} (built on remote host, activated on boot) |
| `just deploy-bootstrap groups='bootstrap'` | Deploy configuration to {{ groups }} (built on current host) |
| `just deploy-dry groups='server'` | Dry test {{ groups }} configuration (built on remote host) |
| `just build-installer` | Build the NixOS installer ISO image |
| `just build-vm host` | Build {{ host }} as a VM (run it with result-vm-{{ host }}/bin/run-{{ host }}-vm) |
| `just generations` | List generations of the system profile |
| `just generations-switch version` | Switch to a specific generation of the system profile |
| `just gc` | Run garbage collection on the Nix store |
| `just repair` | Repair the Nix store |
| `just up` | Update the Nix flake |
| `just sops-rotate` | Rotate Sops keys |
| `just sops-update` | Update Sops keys |
| `just sops-check` | Verify that all encrypted files can be decrypted |
| `just fetch branch='main'` | Fetch the latest changes from the remote repository |
| `just fmt` | Format the Nix code |

Arguments are positional: for example, `just deploy bootstrap`, `just build-vm leviathan`, or `just generations-switch 42`. `just fmt` also runs `nix flake check --no-build` and `statix check`. `generations-switch` selects the generation for the next boot. Deployment recipes pass `--skip-checks`.

> [!CAUTION]
> `just fetch` runs `git reset --hard` and recreates the selected branch from `origin`, discarding tracked local changes. `just gc` deletes old generations and store paths, reducing rollback options.

Targets can also be referenced directly as `.#leviathan` or `.#apeiron` (e.g. `nixos-rebuild switch --flake .#leviathan`).

> [!WARNING]
> Deployment and activation require the host's age key. On a machine without it, `just apply` will fail when sops tries to decrypt secrets.

## Installing a new host

See [INSTALL.md](INSTALL.md) for the full guide (host creation, age keys, secrets, disk verification, install, post-boot checks). Quick version — build and boot the installer ISO, then run the interactive `install-host` tool from inside the installer:

```sh
just build-installer
# Write result-iso/*.iso to a USB and boot the target

# On the installer:
sudo install-host
```

`install-host` will:

1. Prompt for the host to install (from `flake.nixosConfigurations`, excluding `installer`)
2. Prompt for and verify the user age key (`&user-<user>`) and host age key (`&host-<host>`) against `.sops.yaml`, and verify decryption of `secrets/users/<user>`, `secrets/common`, and `secrets/<host>`
3. Verify that the configured disks exist and that the host configuration evaluates, display those disks, and require the host name as explicit erase confirmation
4. Wipe and partition the disks declared in the host's disko layout
5. Install the verified host/user keys (using persistent storage where required), copy the flake to the target's configured location, and run `nixos-install` from that copy

For a non-destructive key/decryption check, run `install-host --verify-only <host>` in the installer. The ISO has wireless disabled and password-enabled root SSH access; use a trusted installation network.

> [!CAUTION]
> The installer **erases every disk declared in the selected host's disko configuration**, not every attached disk. These are machine-specific `/dev/disk/by-id/` paths; update and verify them before confirming. Additional filesystem mounts are separate from the disko layout.
>
> Add the age public keys to `.sops.yaml` and re-encrypt secrets with `just sops-update` before installing if they are new.

## Secrets

Secrets live in `secrets/` and are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) and age:

- Host secrets: `secrets/<host>/`
- Shared secrets: `secrets/common/`
- User secrets: `secrets/users/<user>/` (Home Manager)

NixOS host keys are read from `/nix/secret/age-keys.txt` at activation; the user key is read from `~/.config/sops/age/keys.txt`. These existing keys must be supplied; the module does not enable automatic key generation. The installer verifies and places both keys, and the impermanence configuration preserves the user key on the server.

`.sops.yaml` grants shared secrets to both host recipients, host-specific secrets only to that host, and `secrets/users/alvr/` only to the user recipient. Service-specific files live under `secrets/apeiron/services/`. Secrets are not limited to YAML: encrypted environment and tunnel files also belong here.

> [!IMPORTANT]
> Never commit private age keys or plaintext secrets. Commit only encrypted secret files; `.sops.yaml` contains public recipients and creation rules.

## Development

```sh
nix fmt # nixfmt via treefmt
nix flake check --no-build
statix check
```

The dev shell installs a pre-commit hook with [prek](https://github.com/j178/prek) that runs the same three checks. Flake checks include evaluation of both machine configurations on every declared development platform (`modules/hosts/checks.nix`), deploy-rs checks, and (on `x86_64-linux`) installer-script verification and an assertion that VM variants disable auto-upgrades. `--no-build` evaluates checks without executing their build-time tests; use `nix flake check` on a suitable Linux builder to run them.

VM variants disable disko and auto-upgrades, use the standard kernel, and default to 4 GiB RAM and an 8 GiB disk. They use the user alias as the initial login password; treat them as test environments.

Flake inputs are updated by `.forgejo/workflows/update-flake.yml` at 01:00 Europe/Madrid on days matching `*/3` of each month (`0 1 */3 * *`), or manually with `just up`. Both `.forgejo/workflows/pr-checks.yml` and `update-flake.yml` pre-resolve evaluation-time IFD dependencies with `allow-import-from-derivation true` before running `nix flake check --no-build`.
