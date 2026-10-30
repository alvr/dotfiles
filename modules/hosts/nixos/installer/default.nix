{
  inputs,
  lib,
  self,
  ...
}:
let
  installerSystem = "x86_64-linux";

  hosts = lib.filterAttrs (name: _: name != "installer") self.nixosConfigurations;

  hostData = lib.mapAttrs (
    _name: host:
    let
      inherit (host) config;
      user = config.dot.host.user.alias;
    in
    {
      inherit user;
      disks = lib.mapAttrsToList (_: disk: disk.device) config.disko.devices.disk;
      home = config.users.users.${user}.home;
      hostKeyFile = config.sops.age.keyFile;
      userKeyFile = config.home-manager.users.${user}.sops.age.keyFile;

      dotfilesDir =
        if config.fileSystems ? "/etc/nixos" then config.fileSystems."/etc/nixos".device else "/etc/nixos";

      persistRoot =
        if config.environment ? persistence then
          lib.head (lib.attrNames config.environment.persistence)
        else
          null;
    }
  ) hosts;
in
{
  flake.nixosConfigurations.installer = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      {
        boot.zfs.forceImportRoot = false;
        console.keyMap = "es";
        environment.systemPackages = [ self.packages.${installerSystem}.install-host ];

        networking = {
          hostName = "installer";
          wireless.enable = lib.mkForce false;
        };

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [
            "https://cache.nixos.org"
            "https://nyx-cache.chaotic.cx/"
            "https://nix-community.cachix.org"
            "https://devenv.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          ];
        };

        nixpkgs = {
          hostPlatform = installerSystem;
          config.allowUnfree = true;
        };

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "yes";
            PasswordAuthentication = true;
          };
        };

        users.mutableUsers = false;
        users.users.root.hashedPassword = "$y$j9T$5EUoaereT3cCCsYcqj4YX0$pTbNS99OCDmK2PfSLm.FjlBpNi5yabfCLsw1o8lpvR0";

        system.stateVersion = "26.05";
      }
    ];
  };

  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == installerSystem) (
      let
        installHost = pkgs.writeShellApplication {
          name = "install-host";
          runtimeInputs = with pkgs; [
            age
            coreutils
            findutils
            gawk
            jq
            sops
            util-linux
          ];
          text =
            builtins.replaceStrings
              [ "@src@" "@data@" ]
              [ "${self}" "${pkgs.writeText "install-hosts.json" (builtins.toJSON hostData)}" ]
              (builtins.readFile ./install-host.sh);
        };
      in
      {
        packages.install-host = installHost;

        checks.install-host =
          pkgs.runCommand "install-host-check"
            {
              nativeBuildInputs = with pkgs; [
                installHost
                age
                jq
                sops
              ];
            }
            ''
              bash ${./install-host-check.sh} ${./install-host.sh}
              touch $out
            '';

        checks.vm-config =
          assert lib.all (host: !host.config.virtualisation.vmVariant.system.autoUpgrade.enable) (
            lib.attrValues hosts
          );
          pkgs.runCommand "vm-config-check" { } "touch $out";
      }
    );
}
