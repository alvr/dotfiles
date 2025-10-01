{
  description = "alvrlab NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      disko,
      home-manager,
      impermanence,
      nixos-generators,
      sops-nix,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      systems = [ "x86_64-linux" ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      consts = import ./consts.nix;
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

      overlays = [
        (import ./overlays/unstable.nix { inherit nixpkgs-unstable; })
      ];

      mkNixOSConfig =
        modulePaths:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs consts; };
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            impermanence.nixosModules.impermanence
            sops-nix.nixosModules.sops

            (
              { config, pkgs, ... }:
              {
                nixpkgs.overlays = overlays;
              }
            )

            ./modules/nixos
            ./modules/home-manager
          ]
          ++ modulePaths;
        };
    in
    {
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      nixosConfigurations = {
        apeiron = mkNixOSConfig [
          ./hosts/apeiron/configuration.nix
        ];
      };

      packages.x86_64-linux.installer = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        specialArgs = { inherit consts; };
        modules = [
          ./hosts/installer/configuration.nix
        ];
        format = "install-iso";
      };
    };
}
