default:
    just --list

deploy host='apeiron':
    sudo nixos-rebuild switch --flake ".#{{ host }}" --show-trace

test-deploy host='apeiron':
    sudo nixos-rebuild dry-run --flake ".#{{ host }}" --show-trace

fetch:
    git fetch && git reset --hard origin/main

lock:
    nix flake update

up:
    sudo nixos-rebuild --upgrade

fmt:
    nix fmt .

gc:
    sudo nh clean all --ask

repair:
    sudo nix-store --verify --check-contents --repair

sops-edit:
    sops secrets/secrets.yaml

sops-rotate:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops --rotate --in-place "$file"; done

sops-update:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops updatekeys -y "$file"; done
