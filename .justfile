default:
    @just --list

[group('deploy')]
deploy:
    just deploy-test
    nh os switch . --ask --diff always

[group('deploy')]
deploy-boot:
    just deploy-test
    nh os boot . --ask --diff always

[group('deploy')]
deploy-rollback:
    nh os rollback

[group('deploy')]
deploy-test:
    nh os test . --dry --show-trace

[group('generations')]
generations-list:
    sudo nix-env -p /nix/var/nix/profiles/system --list-generations

[group('generations')]
generations-switch version:
    sudo nix-env -p /nix/var/nix/profiles/system --switch-generation {{ version }}
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot

[group('nix')]
gc:
    sudo nh clean all -av
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

[group('nix')]
repair:
    sudo nix-store --verify --check-contents --repair
    
[group('nix')]
up:
    nix flake update

[group('sops')]
sops-edit:
    sops secrets/secrets.yaml

[group('sops')]
sops-rotate:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops --rotate --in-place "$file"; done

[group('sops')]
sops-update:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops updatekeys -y "$file"; done

[group('utils')]
fetch branch='main':
    git fetch --prune
    git reset --hard
    git checkout -B {{ branch }} origin/{{ branch }}

[group('utils')]
fmt:
    nix fmt
    nix flake lock
    nix flake check --all-systems
    statix check

[group('utils')]
installer:
    nix build .#installer

[group('utils')]
rclone action:
    #!/usr/bin/env bash
    set -euo pipefail

    remote="apeiron:/nix/persist/dotfiles"
    local={{invocation_dir()}}

    case "{{action}}" in
    dl)
        src="${remote}"
        dst="${local}"
    ;;
    up)
        src="${local}"
        dst="${remote}"
    ;;
    *)
        echo "Invalid action: {{action}}. Must be 'dl' or 'up'."
        exit 1
    ;;
    esac

    rclone sync --exclude ".git/" --exclude-from .gitignore "${src}" "${dst}" --progress
