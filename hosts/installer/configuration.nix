{
  consts,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/nixos/_i18n.nix
  ];

  networking.hostName = "nixos-installer";
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

  # Execute wpa_passphrase MYSSID passphrase
  networking.wireless = {
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

  system.stateVersion = "25.05";
}
