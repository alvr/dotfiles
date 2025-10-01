default:
    just --list

deploy host='apeiron':
    sudo nixos-rebuild switch --flake ".#{{ host }}" --show-trace

test-deploy host='apeiron':
    sudo nixos-rebuild dry-run --flake ".#{{ host }}" --show-trace --verbose

rollback-deploy:
    sudo nixos-rebuild switch --rollback --show-trace --verbose

installer:
    nix build .#installer

fetch:
    git fetch && git reset --hard origin/main

lock:
    nix flake update

up:
    sudo nix-channel --update && sudo nixos-rebuild switch --upgrade

fmt:
    nix fmt && nix flake check && statix check

gc:
    sudo nh clean all -av

repair:
    sudo nix-store --verify --check-contents --repair

generations-list:
    sudo nix-env -p /nix/var/nix/profiles/system --list-generations

generations-switch version:
    sudo nix-env -p /nix/var/nix/profiles/system --switch-generation {{ version }}
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot

sops-edit:
    sops secrets/secrets.yaml

sops-rotate:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops --rotate --in-place "$file"; done

sops-update:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops updatekeys -y "$file"; done
