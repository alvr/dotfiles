default:
    @just --list

[doc('Apply configuration on current host')]
[group('apply')]
apply:
    nh os switch . --ask --diff always

[doc('Apply configuration on current host, activated on boot')]
[group('apply')]
apply-boot:
    nh os boot . --ask --diff always

[doc('Dry test configuration on current host')]
[group('apply')]
apply-dry:
    nh os test . --dry --show-trace

[doc('Rollback to previous configuration on current host')]
[group('apply')]
apply-rollback:
    nh os rollback

[doc('Deploy configuration to {{ groups }} (built on remote host)')]
[group('deploy')]
deploy groups='server':
    deploy --skip-checks --groups {{ groups }} --targets .

[doc('Deploy configuration to {{ groups }} (built on remote host, activated on boot)')]
[group('deploy')]
deploy-boot groups='server':
    deploy --skip-checks --groups {{ groups }} --targets . --boot

[doc('Deploy configuration to {{ groups }} (built on current host)')]
[group('deploy')]
deploy-bootstrap groups='bootstrap':
    deploy --skip-checks --groups {{ groups }} --targets .

[doc('Dry test {{ groups }} configuration (built on remote host)')]
[group('deploy')]
deploy-dry groups='server':
    deploy --skip-checks --groups {{ groups }} --targets . --dry-activate

[doc('Build the NixOS installer ISO image')]
[group('build')]
build-installer:
    nix build .#nixosConfigurations.installer.config.system.build.isoImage -o result-iso

[doc('Build {{ host }} as a VM (run it with result-vm-{{ host }}/bin/run-{{ host }}-vm)')]
[group('build')]
build-vm host:
    nix build .#nixosConfigurations.{{ host }}.config.system.build.vm -o result-vm-{{ host }}

[doc('List generations of the system profile')]
[group('generations')]
generations:
    doas nix-env -p /nix/var/nix/profiles/system --list-generations

[doc('Switch to a specific generation of the system profile')]
[group('generations')]
generations-switch version:
    doas nix-env -p /nix/var/nix/profiles/system --switch-generation {{ version }}
    doas /nix/var/nix/profiles/system/bin/switch-to-configuration boot

[doc('Run garbage collection on the Nix store')]
[group('nix')]
gc:
    doas nh clean all -av
    doas nix-collect-garbage -d
    nix-collect-garbage -d

[doc('Repair the Nix store')]
[group('nix')]
repair:
    doas nix-store --verify --check-contents --repair

[doc('Update the Nix flake')]
[group('nix')]
up:
    nix flake update

[doc('Rotate Sops keys')]
[group('sops')]
sops-rotate:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops --rotate --in-place "$file"; done

[doc('Update Sops keys')]
[group('sops')]
sops-update:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops updatekeys -y "$file"; done

[doc('Verify that all encrypted files can be decrypted')]
[group('sops')]
sops-check:
    find secrets/ -type f -print0 | while IFS= read -r -d $'\0' file; do sops decrypt "$file" >/dev/null; done

[doc('Fetch the latest changes from the remote repository')]
[group('utils')]
fetch branch='main':
    git fetch --prune
    git reset --hard
    git checkout -B {{ branch }} origin/{{ branch }}

[doc('Format the Nix code')]
[group('utils')]
fmt:
    nix fmt
    nix flake check --no-build
    statix check
