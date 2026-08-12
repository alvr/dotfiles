{
  consts,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../../modules/nixos/i18n.nix
  ];

  boot.zfs.forceImportRoot = false;
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;
  security.sudo.wheelNeedsPassword = false;
  users.users.nixos.initialHashedPassword = lib.mkForce "$6$WiEl3uT8Ll9CHCQ4$PErOPc7a2fPe5GwN.5Bse99iOCBE9HA9dPmQgN0tArj46/YGxNpEoVII8KFkhCLTYpajMMbOXtooO8t9.1BjD/";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    ports = [ 1311 ];
    openFirewall = true;
  };

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
      curl --proto '=https' --tlsv1.2 -fsSL https://git.${consts.domain}/alvr/dotfiles/raw/branch/main/installer.sh | sudo bash
      EOF

      chmod +x /home/nixos/installer.sh
    '';
    deps = [ "users" ];
  };

  system.stateVersion = "25.05";
}
