{
  consts,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/nixos/i18n.nix
  ];

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;
  security.sudo.wheelNeedsPassword = false;
  services.openssh.enable = true;
  users.users.nixos.openssh.authorizedKeys.keys = consts.sshAuthorizedKeys;

  environment.systemPackages = with pkgs; [
    age
    curl
    disko
    envsubst
    git
    neovim
    sops
    ssh-to-age
    yq-go
  ];

  networking = {
    hostName = "nixos-installer";
    networkmanager.enable = lib.mkForce false;

    # Execute wpa_passphrase MYSSID passphrase
    wireless = {
      enable = true;
      networks = lib.mkForce { };
      extraConfig = ''
        update_config=1
        fast_reauth=1

        network={
          ssid=
          psk=
        }
      '';
    };
  };

  system.activationScripts.createInstallerFile = {
    text = ''
      echo "Creating installer file in /home/nixos..." >&2
      cat > /home/nixos/installer.sh << 'EOF'

      #!/usr/bin/env bash
      curl --proto '=https' --tlsv1.2 -fsSL https://git.alvr.dev/alvr/dotfiles/raw/branch/main/installer.sh | sudo bash
      EOF

      chmod +x /home/nixos/installer.sh
    '';
    deps = [ "users" ];
  };

  system.stateVersion = "25.05";
}
