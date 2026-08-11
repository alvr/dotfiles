{
  description = "alvr's dotfiles NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    determinate.url = "github:DeterminateSystems/determinate";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      determinate,
      home-manager,
      impermanence,
      sops-nix,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      systems = [ "x86_64-linux" ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      lib = import ./lib/extend.nix { inherit inputs self; };
      consts = import ./consts.nix;
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

      mkNixOSConfig =
        modulePaths:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              consts
              lib
              inputs
              outputs
              ;
          };
          modules = [
            disko.nixosModules.disko
            determinate.nixosModules.default
            home-manager.nixosModules.home-manager
            impermanence.nixosModules.impermanence
            sops-nix.nixosModules.sops

            ./modules/nixos
            ./modules/home-manager
          ]
          ++ modulePaths;
        };
    in
    {
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);

      nixosConfigurations = {
        apeiron = mkNixOSConfig [
          ./hosts/apeiron/configuration.nix
        ];
      };

      packages.x86_64-linux.installer =
        (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit consts lib; };
          modules = [
            ./hosts/installer/configuration.nix
          ];
        }).config.system.build.isoImage;
    };
}
