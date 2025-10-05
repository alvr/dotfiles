default:
    @just --list

fetch:
    git fetch && git reset --hard origin/main

fmt:
    nix fmt && nix flake check && statix check

gc:
    sudo nh clean all -av

installer:
    nix build .#installer

lock:
    nix flake update

repair:
    sudo nix-store --verify --check-contents --repair

up:
    sudo nix-channel --update && sudo nixos-rebuild switch --upgrade

[group('deploy')]
deploy host='apeiron':
    just deploy-test {{ host }}
    sudo nixos-rebuild switch --flake ".#{{ host }}" --show-trace --verbose

[group('deploy')]
deploy-rollback:
    sudo nixos-rebuild switch --rollback --show-trace --verbose

[group('deploy')]
deploy-test host='apeiron':
    sudo nixos-rebuild dry-run --flake ".#{{ host }}" --show-trace --verbose

[group('generations')]
generations-list:
    sudo nix-env -p /nix/var/nix/profiles/system --list-generations

[group('generations')]
generations-switch version:
    sudo nix-env -p /nix/var/nix/profiles/system --switch-generation {{ version }}
    sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot

[group('sops')]
sops-edit:
    sops secrets/secrets.yaml

[group('sops')]
sops-rotate:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops --rotate --in-place "$file"; done

[group('sops')]
sops-update:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops updatekeys -y "$file"; done
