default:
    @just --list

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

[group('nix')]
gc:
    sudo nh clean all -av
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

[group('nix')]
repair:
    sudo nix-store --verify --check-contents --repair

[group('sops')]
sops-edit:
    sops secrets/secrets.yaml

[group('sops')]
sops-rotate:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops --rotate --in-place "$file"; done

[group('sops')]
sops-update:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops updatekeys -y "$file"; done

[group('update')]
lock:
    nix flake update

[group('update')]
up:
    sudo nix-channel --update
    sudo nixos-rebuild switch --upgrade

[group('utils')]
fetch:
    git fetch
    git reset --hard origin/main

[group('utils')]
fmt:
    nix fmt
    nix flake check
    statix check

[group('utils')]
installer:
    nix build .#installer
